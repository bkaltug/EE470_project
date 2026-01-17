import torch
import torch.nn as nn
import torch.nn.functional as F
import numpy as np
import os

# Define the model architecture (same as data_nn.py)
class TrafficSignClassifier(nn.Module):
    def __init__(self, num_classes):
        super(TrafficSignClassifier, self).__init__()
        
        self.conv1 = nn.Conv2d(in_channels=3, out_channels=32, kernel_size=5)
        self.conv2 = nn.Conv2d(in_channels=32, out_channels=64, kernel_size=3)
        self.pool = nn.MaxPool2d(kernel_size=2, stride=2)
        self.dropout = nn.Dropout(p=0.5)
        self.fc1 = nn.Linear(64 * 5 * 5, 128)
        self.fc2 = nn.Linear(128, num_classes)
  
    def forward(self, x):
        x = self.pool(F.relu(self.conv1(x)))
        x = self.pool(F.relu(self.conv2(x)))
        x = torch.flatten(x, 1)
        x = self.dropout(x)
        x = F.relu(self.fc1(x))
        x = self.fc2(x)
        return x


def convert_pytorch_to_tflite():
    # Paths
    pytorch_model_path = './models/simple_cnn_traffic_sign.pth'
    onnx_model_path = './models/traffic_sign_model.onnx'
    tflite_model_path = './models/traffic_sign_model.tflite'
    
    NUM_CLASSES = 29
    INPUT_SIZE = 30  # 30x30 images as per training
    
    # Load PyTorch model
    print("Loading PyTorch model...")
    model = TrafficSignClassifier(num_classes=NUM_CLASSES)
    model.load_state_dict(torch.load(pytorch_model_path, map_location='cpu'))
    model.eval()
    
    # Create dummy input for export (batch_size=1, channels=3, height=30, width=30)
    dummy_input = torch.randn(1, 3, INPUT_SIZE, INPUT_SIZE)
    
    # Export to ONNX
    print("Exporting to ONNX...")
    torch.onnx.export(
        model,
        dummy_input,
        onnx_model_path,
        export_params=True,
        opset_version=13,
        do_constant_folding=True,
        input_names=['input'],
        output_names=['output'],
        dynamic_axes={
            'input': {0: 'batch_size'},
            'output': {0: 'batch_size'}
        }
    )
    print(f"ONNX model saved to: {onnx_model_path}")
    
    # Convert ONNX to TensorFlow SavedModel using tf2onnx
    print("Converting ONNX to TensorFlow...")
    import subprocess
    
    tf_saved_model_path = './models/tf_saved_model'
    
    # Use onnx-tf to convert (alternative approach using subprocess)
    result = subprocess.run([
        'python', '-m', 'tf2onnx.convert',
        '--reverse',
        '--input', onnx_model_path,
        '--output', tf_saved_model_path
    ], capture_output=True, text=True)
    
    if result.returncode != 0:
        print("tf2onnx reverse conversion not available, using direct TFLite conversion...")
        # Alternative: Direct conversion using TensorFlow Lite
        convert_onnx_to_tflite_direct(onnx_model_path, tflite_model_path, INPUT_SIZE)
    else:
        # Convert SavedModel to TFLite
        import tensorflow as tf
        converter = tf.lite.TFLiteConverter.from_saved_model(tf_saved_model_path)
        tflite_model = converter.convert()
        
        with open(tflite_model_path, 'wb') as f:
            f.write(tflite_model)
        print(f"TFLite model saved to: {tflite_model_path}")


def convert_onnx_to_tflite_direct(onnx_path, tflite_path, input_size):
    """
    Alternative conversion method using ONNX Runtime and manual TFLite creation.
    """
    import onnx
    from onnx import numpy_helper
    import tensorflow as tf
    
    print("Using direct ONNX to TFLite conversion...")
    
    # Load ONNX model
    onnx_model = onnx.load(onnx_path)
    onnx.checker.check_model(onnx_model)
    
    # Create equivalent TensorFlow model
    model = create_tf_model_from_pytorch(input_size)
    
    # Load weights from ONNX to TF model
    load_onnx_weights_to_tf(onnx_model, model)
    
    # Convert to TFLite
    print("Converting to TFLite...")
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_model = converter.convert()
    
    with open(tflite_path, 'wb') as f:
        f.write(tflite_model)
    
    print(f"TFLite model saved to: {tflite_path}")
    
    # Verify the model
    verify_tflite_model(tflite_path)


def create_tf_model_from_pytorch(input_size):
    """
    Create TensorFlow/Keras model with same architecture as PyTorch model.
    Note: PyTorch uses NCHW format, TensorFlow uses NHWC format.
    """
    import tensorflow as tf
    import keras
    from keras import layers
    
    # Input shape for TensorFlow (NHWC format)
    inputs = keras.Input(shape=(input_size, input_size, 3), name='input')
    
    # Conv1: 3 -> 32, kernel=5
    x = layers.Conv2D(32, kernel_size=5, padding='valid', name='conv1')(inputs)
    x = layers.ReLU()(x)
    x = layers.MaxPooling2D(pool_size=2, strides=2)(x)
    
    # Conv2: 32 -> 64, kernel=3
    x = layers.Conv2D(64, kernel_size=3, padding='valid', name='conv2')(x)
    x = layers.ReLU()(x)
    x = layers.MaxPooling2D(pool_size=2, strides=2)(x)
    
    # Flatten
    x = layers.Flatten()(x)
    
    # Note: Dropout is typically not used during inference
    # FC1: -> 128
    x = layers.Dense(128, activation='relu', name='fc1')(x)
    
    # FC2: -> 29 (num_classes)
    outputs = layers.Dense(29, name='fc2')(x)
    
    model = keras.Model(inputs=inputs, outputs=outputs, name='traffic_sign_classifier')
    return model


def load_onnx_weights_to_tf(onnx_model, tf_model):
    """
    Load weights from ONNX model to TensorFlow model.
    Handles the NCHW to NHWC conversion for conv weights.
    """
    import onnx
    from onnx import numpy_helper
    
    # Get ONNX weights
    onnx_weights = {}
    for initializer in onnx_model.graph.initializer:
        onnx_weights[initializer.name] = numpy_helper.to_array(initializer)
    
    print(f"ONNX weights found: {list(onnx_weights.keys())}")
    
    import keras
    
    # Map ONNX weights to TF layers
    for layer in tf_model.layers:
        if isinstance(layer, keras.layers.Conv2D):
            layer_name = layer.name
            # ONNX conv weights are in OIHW format, TF needs HWIO
            if 'conv1' in layer_name:
                weight_key = 'conv1.weight'
                bias_key = 'conv1.bias'
            elif 'conv2' in layer_name:
                weight_key = 'conv2.weight'
                bias_key = 'conv2.bias'
            else:
                continue
            
            if weight_key in onnx_weights:
                # Convert from OIHW (PyTorch) to HWIO (TensorFlow)
                onnx_weight = onnx_weights[weight_key]
                tf_weight = np.transpose(onnx_weight, (2, 3, 1, 0))
                
                weights_to_set = [tf_weight]
                if bias_key in onnx_weights:
                    weights_to_set.append(onnx_weights[bias_key])
                
                layer.set_weights(weights_to_set)
                print(f"Loaded weights for {layer_name}")
        
        elif isinstance(layer, keras.layers.Dense):
            layer_name = layer.name
            if 'fc1' in layer_name:
                weight_key = 'fc1.weight'
                bias_key = 'fc1.bias'
            elif 'fc2' in layer_name:
                weight_key = 'fc2.weight'
                bias_key = 'fc2.bias'
            else:
                continue
            
            if weight_key in onnx_weights:
                # Dense weights need to be transposed
                onnx_weight = onnx_weights[weight_key]
                tf_weight = np.transpose(onnx_weight)
                
                weights_to_set = [tf_weight]
                if bias_key in onnx_weights:
                    weights_to_set.append(onnx_weights[bias_key])
                
                layer.set_weights(weights_to_set)
                print(f"Loaded weights for {layer_name}")


def verify_tflite_model(tflite_path):
    """Verify the TFLite model can run inference."""
    import tensorflow as tf
    
    print("\nVerifying TFLite model...")
    
    # Load TFLite model
    interpreter = tf.lite.Interpreter(model_path=tflite_path)
    interpreter.allocate_tensors()
    
    # Get input and output details
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    print(f"Input shape: {input_details[0]['shape']}")
    print(f"Input dtype: {input_details[0]['dtype']}")
    print(f"Output shape: {output_details[0]['shape']}")
    print(f"Output dtype: {output_details[0]['dtype']}")
    
    # Test with random input
    input_shape = input_details[0]['shape']
    test_input = np.random.rand(*input_shape).astype(np.float32)
    
    interpreter.set_tensor(input_details[0]['index'], test_input)
    interpreter.invoke()
    
    output = interpreter.get_tensor(output_details[0]['index'])
    print(f"Test inference output shape: {output.shape}")
    print(f"Predicted class: {np.argmax(output)}")
    print("\nTFLite model verification successful!")


if __name__ == '__main__':
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    convert_pytorch_to_tflite()
