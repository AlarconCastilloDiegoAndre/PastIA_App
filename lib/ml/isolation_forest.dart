// lib/ml/isolation_forest.dart
import 'dart:math';
import 'package:pastillero_inteligente/models/medication_history_model.dart';

/// Implementación de Isolation Forest para detección de anomalías
/// en patrones de toma de medicamentos.
class IsolationForest {
  // Hiperparámetros del modelo
  final int _nTrees; // Número de árboles en el bosque
  final int _maxSamples; // Máximo número de muestras por árbol
  final double _contaminationFactor; // Factor de contaminación esperado (% de anomalías)
  
  // Variables internas del modelo
  List<_IsolationTree> _trees = [];
  late double _threshold; // Umbral para determinar si una muestra es anómala
  bool _isFitted = false; // Indica si el modelo ya ha sido entrenado
  
  // Constructor
  IsolationForest({
    int nTrees = 100,
    int? maxSamples,
    double contaminationFactor = 0.1,
  }) : _nTrees = nTrees,
       _maxSamples = maxSamples ?? 256,
       _contaminationFactor = contaminationFactor;
  
  /// Entrena el modelo con los datos históricos de medicamentos
  void fit(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      throw Exception('No hay datos para entrenar el modelo');
    }
    
    try {
      // Limitar el número de muestras si es necesario
      final int nSamples = min(data.length, _maxSamples);
      
      // Generar los árboles
      _trees = List.generate(_nTrees, (_) {
        // Muestreo aleatorio para cada árbol
        final sampledData = _sampleData(data, nSamples);
        // Crear un nuevo árbol con el constructor adecuado
        final tree = _IsolationTree();
        tree.buildTree(sampledData, 0, _calculateHeightLimit(nSamples));
        return tree;
      });
      
      // Calcular puntuaciones de anomalías para todas las muestras
      final List<double> anomalyScores = data.map((sample) => 
        _computeAnomalyScore(sample)
      ).toList();
      
      // Ordenar las puntuaciones
      anomalyScores.sort();
      
      // Determinar el umbral basado en el factor de contaminación
      final int thresholdIdx = (data.length * (1 - _contaminationFactor)).floor();
      _threshold = thresholdIdx < anomalyScores.length 
          ? anomalyScores[thresholdIdx] 
          : anomalyScores.last;
      
      _isFitted = true;
    } catch (e) {
      throw Exception('Error durante el entrenamiento del modelo: $e');
    }
  }
  
  /// Predice si una muestra es anómala (1) o normal (0)
  int predict(Map<String, dynamic> sample) {
    if (!_isFitted) {
      throw Exception('El modelo debe ser entrenado primero con fit()');
    }
    
    final double score = _computeAnomalyScore(sample);
    return score > _threshold ? 1 : 0;
  }
  
  /// Calcula la puntuación de anomalía para una muestra
  double getAnomalyScore(Map<String, dynamic> sample) {
    if (!_isFitted) {
      throw Exception('El modelo debe ser entrenado primero con fit()');
    }
    
    return _computeAnomalyScore(sample);
  }
  
  /// Computa la puntuación de anomalía promediando la longitud de camino en todos los árboles
  double _computeAnomalyScore(Map<String, dynamic> sample) {
    // Calcular la longitud media del camino (promedio de todos los árboles)
    double totalPathLength = 0.0;
    for (var tree in _trees) {
      totalPathLength += tree.pathLength(sample, 0);
    }
    final double avgPathLength = totalPathLength / _trees.length;
    
    // Calcular el factor de normalización (c)
    final int n = min(_maxSamples, sample.length);
    final double c = _avgPathLengthFactor(n);
    
    // Calcular la puntuación de anomalía normalizada
    return pow(2, -avgPathLength / c).toDouble();
  }
  
  /// Selecciona muestras aleatorias del conjunto de datos
  List<Map<String, dynamic>> _sampleData(List<Map<String, dynamic>> data, int nSamples) {
    if (nSamples >= data.length) {
      return List.from(data);
    }
    
    final random = Random();
    final List<Map<String, dynamic>> sampledData = [];
    final Set<int> selectedIndices = {};
    
    while (selectedIndices.length < nSamples) {
      final int idx = random.nextInt(data.length);
      if (!selectedIndices.contains(idx)) {
        selectedIndices.add(idx);
        sampledData.add(data[idx]);
      }
    }
    
    return sampledData;
  }
  
  /// Calcula la altura límite para los árboles
  int _calculateHeightLimit(int nSamples) {
    return (log(nSamples) / log(2)).ceil();
  }
  
  /// Factor de normalización para la longitud media del camino
  double _avgPathLengthFactor(int n) {
    if (n <= 1) return 1.0;
    double result = 2 * (_harmonic(n - 1) - (n - 1) / n);
    return result;
  }
  
  /// Función para calcular la suma armónica (H(i))
  double _harmonic(int i) {
    double sum = 0;
    for (int j = 1; j <= i; j++) {
      sum += 1 / j;
    }
    return sum;
  }
  
  /// Serializa el modelo a un mapa para almacenamiento
  Map<String, dynamic> toJson() {
    if (!_isFitted) {
      throw Exception('El modelo debe ser entrenado primero con fit()');
    }
    
    return {
      'nTrees': _nTrees,
      'maxSamples': _maxSamples,
      'contaminationFactor': _contaminationFactor,
      'threshold': _threshold,
      'trees': _trees.map((tree) => tree.toJson()).toList(),
    };
  }
  
  /// Carga un modelo desde un mapa
  factory IsolationForest.fromJson(Map<String, dynamic> json) {
    final forest = IsolationForest(
      nTrees: json['nTrees'],
      maxSamples: json['maxSamples'],
      contaminationFactor: json['contaminationFactor'],
    );
    
    forest._threshold = json['threshold'];
    forest._trees = (json['trees'] as List)
        .map((treeJson) => _IsolationTree.fromJson(treeJson as Map<String, dynamic>))
        .toList();
    forest._isFitted = true;
    
    return forest;
  }
  
  /// Prepara los datos del historial de medicamentos para el modelo
  static List<Map<String, dynamic>> prepareDataFromHistory(
    List<MedicationHistory> history,
    String medicationId,
  ) {
    // Filtrar por medicamento específico
    final medicationHistory = history
        .where((item) => item.medicationId == medicationId)
        .toList();
    
    // Extraer características relevantes
    return medicationHistory.map((item) {
      final Map<String, dynamic> features = {
        'wasTaken': item.wasTaken ? 1.0 : 0.0,
        'deviationMinutes': item.deviationMinutes?.toDouble() ?? 0.0,
        'dayOfWeek': item.context?.dayOfWeek.toDouble() ?? DateTime.now().weekday.toDouble(),
        'isWeekend': item.context?.isWeekend == true ? 1.0 : 0.0,
        'hourOfDay': item.scheduledDateTime.hour.toDouble(),
      };
      
      // Añadir más características si están disponibles
      if (item.context != null) {
        features['adherenceStreak'] = item.context!.adherenceStreak.toDouble();
        features['isHoliday'] = item.context!.isHoliday == true ? 1.0 : 0.0;
        features['wasTravelDay'] = item.context!.wasTravelDay == true ? 1.0 : 0.0;
      }
      
      return features;
    }).toList();
  }
}

/// Clase auxiliar para representar un nodo en el árbol de aislamiento
class _IsolationTreeNode {
  double? splitValue;
  String? splitAttribute;
  _IsolationTreeNode? left;
  _IsolationTreeNode? right;
  bool isLeaf = false;
  int size = 0;
  
  // Constructor explícito
  _IsolationTreeNode();
  
  Map<String, dynamic> toJson() {
    return {
      'splitValue': splitValue,
      'splitAttribute': splitAttribute,
      'left': left?.toJson(),
      'right': right?.toJson(),
      'isLeaf': isLeaf,
      'size': size,
    };
  }
  
  factory _IsolationTreeNode.fromJson(Map<String, dynamic> json) {
    final node = _IsolationTreeNode();
    node.splitValue = json['splitValue'] as double?;
    node.splitAttribute = json['splitAttribute'] as String?;
    node.isLeaf = json['isLeaf'] as bool;
    node.size = json['size'] as int;
    
    if (json['left'] != null) {
      node.left = _IsolationTreeNode.fromJson(json['left'] as Map<String, dynamic>);
    }
    
    if (json['right'] != null) {
      node.right = _IsolationTreeNode.fromJson(json['right'] as Map<String, dynamic>);
    }
    
    return node;
  }
}

/// Clase para representar un árbol de aislamiento
class _IsolationTree {
  _IsolationTreeNode? _root;
  final Random _random = Random();
  
  // Constructor explícito
  _IsolationTree();
  
  /// Construye el árbol recursivamente
  void buildTree(List<Map<String, dynamic>> data, int currentHeight, int heightLimit) {
    _root = _buildTreeRecursive(data, currentHeight, heightLimit);
  }
  
  /// Función recursiva para construir el árbol
  _IsolationTreeNode _buildTreeRecursive(
    List<Map<String, dynamic>> data,
    int currentHeight,
    int heightLimit,
  ) {
    final node = _IsolationTreeNode();
    
    // Condiciones de parada
    if (currentHeight >= heightLimit || data.length <= 1) {
      node.isLeaf = true;
      node.size = data.length;
      return node;
    }
    
    // Seleccionar un atributo aleatorio para la división
    if (data.isEmpty || data[0].isEmpty) {
      node.isLeaf = true;
      node.size = data.length;
      return node;
    }
    
    final attributes = data[0].keys.toList();
    final selectedAttr = attributes[_random.nextInt(attributes.length)];
    node.splitAttribute = selectedAttr;
    
    // Encontrar el valor mínimo y máximo para el atributo seleccionado
    double? minValue, maxValue;
    for (var sample in data) {
      final value = sample[selectedAttr];
      if (value is num) {
        final doubleValue = value.toDouble();
        if (minValue == null || doubleValue < minValue) minValue = doubleValue;
        if (maxValue == null || doubleValue > maxValue) maxValue = doubleValue;
      }
    }
    
    // Si todos los valores son iguales, crear un nodo hoja
    if (minValue == null || maxValue == null || minValue == maxValue) {
      node.isLeaf = true;
      node.size = data.length;
      return node;
    }
    
    // Seleccionar un valor aleatorio entre mínimo y máximo
    node.splitValue = minValue + _random.nextDouble() * (maxValue - minValue);
    
    // Dividir los datos
    final leftData = <Map<String, dynamic>>[];
    final rightData = <Map<String, dynamic>>[];
    
    for (var sample in data) {
      final value = sample[selectedAttr];
      if (value is num && value < node.splitValue!) {
        leftData.add(sample);
      } else {
        rightData.add(sample);
      }
    }
    
    // Construir subárboles
    node.left = _buildTreeRecursive(leftData, currentHeight + 1, heightLimit);
    node.right = _buildTreeRecursive(rightData, currentHeight + 1, heightLimit);
    
    return node;
  }
  
  /// Calcula la longitud del camino para una muestra en el árbol
  double pathLength(Map<String, dynamic> sample, int currentHeight) {
    if (_root == null) {
      return currentHeight.toDouble();
    }
    return _pathLengthRecursive(_root!, sample, currentHeight);
  }
  
  /// Función recursiva para calcular la longitud del camino
  double _pathLengthRecursive(_IsolationTreeNode node, Map<String, dynamic> sample, int currentHeight) {
    if (node.isLeaf) {
      // Cálculo de la longitud del camino para nodos hoja
      return currentHeight + _cFactor(node.size);
    }
    
    if (node.splitAttribute == null || node.splitValue == null) {
      return currentHeight + 1.0;
    }
    
    final value = sample[node.splitAttribute];
    if (value is num && value < node.splitValue!) {
      if (node.left != null) {
        return _pathLengthRecursive(node.left!, sample, currentHeight + 1);
      }
    } else {
      if (node.right != null) {
        return _pathLengthRecursive(node.right!, sample, currentHeight + 1);
      }
    }
    
    // Si llegamos aquí, algo salió mal
    return currentHeight + 1.0;
  }
  
  /// Factor de corrección para la longitud del camino
  double _cFactor(int size) {
    if (size <= 1) return 0.0;
    return 2.0 * (log(size - 1.0) + 0.5772156649) - (2.0 * (size - 1.0) / size);
  }
  
  /// Serializa el árbol a un mapa
  Map<String, dynamic> toJson() {
    return {
      'root': _root?.toJson(),
    };
  }
  
  /// Carga un árbol desde un mapa
  factory _IsolationTree.fromJson(Map<String, dynamic> json) {
    final tree = _IsolationTree();
    if (json['root'] != null) {
      tree._root = _IsolationTreeNode.fromJson(json['root'] as Map<String, dynamic>);
    }
    return tree;
  }
}