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


def convert_model():
    import tensorflow as tf
    
    # Paths
    pytorch_model_path = './models/simple_cnn_traffic_sign.pth'
    tflite_model_path = './models/traffic_sign_model.tflite'
    
    NUM_CLASSES = 29
    INPUT_SIZE = 30
    
    # Load PyTorch model
    print("Loading PyTorch model...")
    pytorch_model = TrafficSignClassifier(num_classes=NUM_CLASSES)
    pytorch_model.load_state_dict(torch.load(pytorch_model_path, map_location='cpu', weights_only=True))
    pytorch_model.eval()
    
    # Extract weights from PyTorch model
    print("Extracting PyTorch weights...")
    pytorch_weights = {}
    for name, param in pytorch_model.named_parameters():
        pytorch_weights[name] = param.detach().numpy()
        print(f"  {name}: {param.shape}")
    
    # Create TensorFlow/Keras model
    print("\nCreating TensorFlow model...")
    
    # Input: NHWC format for TensorFlow (batch, height, width, channels)
    inputs = tf.keras.Input(shape=(INPUT_SIZE, INPUT_SIZE, 3), name='input')
    
    # Conv1: 5x5 kernel, 32 filters
    x = tf.keras.layers.Conv2D(32, kernel_size=5, padding='valid', activation='relu', name='conv1')(inputs)
    x = tf.keras.layers.MaxPooling2D(pool_size=2, strides=2)(x)
    
    # Conv2: 3x3 kernel, 64 filters  
    x = tf.keras.layers.Conv2D(64, kernel_size=3, padding='valid', activation='relu', name='conv2')(x)
    x = tf.keras.layers.MaxPooling2D(pool_size=2, strides=2)(x)
    
    # Flatten
    x = tf.keras.layers.Flatten()(x)
    
    # FC1: 128 units
    x = tf.keras.layers.Dense(128, activation='relu', name='fc1')(x)
    
    # FC2: output layer (no softmax - raw logits like PyTorch)
    outputs = tf.keras.layers.Dense(NUM_CLASSES, name='fc2')(x)
    
    tf_model = tf.keras.Model(inputs=inputs, outputs=outputs, name='traffic_sign_classifier')
    
    # Transfer weights from PyTorch to TensorFlow
    print("\nTransferring weights...")
    
    for layer in tf_model.layers:
        if isinstance(layer, tf.keras.layers.Conv2D):
            weight_name = f"{layer.name}.weight"
            bias_name = f"{layer.name}.bias"
            
            if weight_name in pytorch_weights:
                # PyTorch Conv2D weights: [out_channels, in_channels, H, W] (OIHW)
                # TensorFlow Conv2D weights: [H, W, in_channels, out_channels] (HWIO)
                pt_weight = pytorch_weights[weight_name]
                tf_weight = np.transpose(pt_weight, (2, 3, 1, 0))
                
                weights = [tf_weight]
                if bias_name in pytorch_weights:
                    weights.append(pytorch_weights[bias_name])
                
                layer.set_weights(weights)
                print(f"  Set weights for {layer.name}")
        
        elif isinstance(layer, tf.keras.layers.Dense):
            weight_name = f"{layer.name}.weight"
            bias_name = f"{layer.name}.bias"
            
            if weight_name in pytorch_weights:
                # PyTorch Linear weights: [out_features, in_features]
                # TensorFlow Dense weights: [in_features, out_features]
                pt_weight = pytorch_weights[weight_name]
                
                # For fc1 (first dense layer after flatten), we need to handle
                # the different memory layout between PyTorch (NCHW) and TF (NHWC)
                # PyTorch flattens: [batch, C, H, W] -> [batch, C*H*W]
                # TensorFlow flattens: [batch, H, W, C] -> [batch, H*W*C]
                if layer.name == 'fc1':
                    # Input to fc1 is 64 channels, 5x5 spatial
                    # PyTorch: flatten [64, 5, 5] in order C, H, W -> 1600
                    # TensorFlow: flatten [5, 5, 64] in order H, W, C -> 1600
                    # We need to rearrange the weight input dimension
                    C, H, W = 64, 5, 5
                    # pt_weight shape: [128, 1600]
                    # Reshape to [128, 64, 5, 5] (NCHW order)
                    reshaped = pt_weight.reshape(128, C, H, W)
                    # Transpose to [128, 5, 5, 64] (NHWC order)
                    reshaped = np.transpose(reshaped, (0, 2, 3, 1))
                    # Flatten back to [128, 1600]
                    tf_weight = reshaped.reshape(128, -1)
                    # Final transpose for Dense layer format
                    tf_weight = np.transpose(tf_weight)
                else:
                    tf_weight = np.transpose(pt_weight)
                
                weights = [tf_weight]
                if bias_name in pytorch_weights:
                    weights.append(pytorch_weights[bias_name])
                
                layer.set_weights(weights)
                print(f"  Set weights for {layer.name}")
    
    # Verify model with test input
    print("\nVerifying TensorFlow model...")
    
    # Create test input (NHWC for TF)
    test_input_tf = np.random.rand(1, INPUT_SIZE, INPUT_SIZE, 3).astype(np.float32)
    tf_output = tf_model.predict(test_input_tf, verbose=0)
    
    # Create equivalent PyTorch input (NCHW)
    test_input_pt = torch.from_numpy(np.transpose(test_input_tf, (0, 3, 1, 2)))
    with torch.no_grad():
        pt_output = pytorch_model(test_input_pt).numpy()
    
    print(f"  PyTorch output: {pt_output[0][:5]}...")
    print(f"  TensorFlow output: {tf_output[0][:5]}...")
    print(f"  Max difference: {np.max(np.abs(pt_output - tf_output))}")
    
    # Convert to TFLite
    print("\nConverting to TFLite...")
    converter = tf.lite.TFLiteConverter.from_keras_model(tf_model)
    
    # Optional: Add optimizations
    # converter.optimizations = [tf.lite.Optimize.DEFAULT]
    
    tflite_model = converter.convert()
    
    # Save TFLite model
    with open(tflite_model_path, 'wb') as f:
        f.write(tflite_model)
    
    print(f"\nTFLite model saved to: {tflite_model_path}")
    print(f"Model size: {os.path.getsize(tflite_model_path) / 1024:.2f} KB")
    
    # Verify TFLite model
    print("\nVerifying TFLite model...")
    interpreter = tf.lite.Interpreter(model_path=tflite_model_path)
    interpreter.allocate_tensors()
    
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    print(f"  Input: shape={input_details[0]['shape']}, dtype={input_details[0]['dtype']}")
    print(f"  Output: shape={output_details[0]['shape']}, dtype={output_details[0]['dtype']}")
    
    # Test TFLite inference
    interpreter.set_tensor(input_details[0]['index'], test_input_tf)
    interpreter.invoke()
    tflite_output = interpreter.get_tensor(output_details[0]['index'])
    
    print(f"  TFLite output: {tflite_output[0][:5]}...")
    print(f"  Max difference (TF vs TFLite): {np.max(np.abs(tf_output - tflite_output))}")
    
    print("\n✅ Conversion completed successfully!")
    
    return tflite_model_path


if __name__ == '__main__':
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    convert_model()
