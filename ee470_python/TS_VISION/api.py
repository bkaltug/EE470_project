import torch
import torch.nn.functional as F
from torchvision import transforms
from PIL import Image, ExifTags
import io
from flask import Flask, request, jsonify
from data_nn import TrafficSignClassifier, device

app = Flask(__name__)

# --- 1. SETUP MODEL (Load once when server starts) ---
MODEL_PATH = './models/simple_cnn_traffic_sign.pth'
NUM_CLASSES = 29 

# Load class names
with open('./dataset/valid/_classes.txt', 'r') as f:
    class_names = [line.strip() for line in f.readlines()]

# Initialize Model
model = TrafficSignClassifier(num_classes=NUM_CLASSES)
model.load_state_dict(torch.load(MODEL_PATH, map_location=device))
model.to(device)
model.eval()

# Define Transform (Same as training)
test_transform = transforms.Compose([
    transforms.Resize((30, 30)),
    transforms.ToTensor(),
])

def fix_image_orientation(image):
    """
    Fix image orientation based on EXIF data.
    Camera photos often have rotation metadata that needs to be applied.
    """
    try:
        # Get EXIF data
        exif = image._getexif()
        if exif is None:
            return image
        
        # Find the orientation tag
        orientation_key = None
        for key, value in ExifTags.TAGS.items():
            if value == 'Orientation':
                orientation_key = key
                break
        
        if orientation_key is None or orientation_key not in exif:
            return image
        
        orientation = exif[orientation_key]
        
        # Apply rotation based on orientation value
        if orientation == 2:
            image = image.transpose(Image.FLIP_LEFT_RIGHT)
        elif orientation == 3:
            image = image.rotate(180, expand=True)
        elif orientation == 4:
            image = image.transpose(Image.FLIP_TOP_BOTTOM)
        elif orientation == 5:
            image = image.transpose(Image.FLIP_LEFT_RIGHT).rotate(270, expand=True)
        elif orientation == 6:
            image = image.rotate(270, expand=True)
        elif orientation == 7:
            image = image.transpose(Image.FLIP_LEFT_RIGHT).rotate(90, expand=True)
        elif orientation == 8:
            image = image.rotate(90, expand=True)
            
    except (AttributeError, KeyError, IndexError, TypeError):
        # If anything goes wrong, just return the original image
        pass
    
    return image

# --- 2. DEFINE THE ENDPOINT ---
@app.route('/predict', methods=['POST'])
def predict():
    if 'file' not in request.files:
        return jsonify({'error': 'No file part'}), 400
    
    file = request.files['file']
    
    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400

    try:
        # Read image file from memory (don't need to save to disk)
        image_bytes = file.read()
        image = Image.open(io.BytesIO(image_bytes))
        
        # Fix orientation for camera photos (EXIF rotation)
        image = fix_image_orientation(image)
        
        # Convert to RGB after fixing orientation
        image = image.convert('RGB')
        
        # Transform image
        image_tensor = test_transform(image).unsqueeze(0).to(device)

        # Predict
        with torch.no_grad():
            outputs = model(image_tensor)
            probs = F.softmax(outputs, dim=1)
            predicted_class = torch.argmax(probs, dim=1).item()
            predicted_label = class_names[predicted_class]
            confidence = probs[0][predicted_class].item()

        # Return result as JSON
        return jsonify({
            'class_id': predicted_class,
            'label': predicted_label,
            'confidence': f"{confidence:.2f}"
        })

    except Exception as e:
        return jsonify({'error': str(e)}), 500

# --- 3. RUN SERVER ---
if __name__ == '__main__':
    # host='0.0.0.0' allows external devices (like your phone) to connect
    app.run(host='0.0.0.0', port=5000, debug=True)