import torch
from torch.utils.data import DataLoader, Dataset
from torchvision import transforms
from PIL import Image
import os
import numpy as np
import random
from collections import Counter
from data_nn import TrafficSignClassifier, train_model, device, model, criterion, optimizer 

#dataloader
class AnnotationDataset(Dataset):
    def __init__(self, annotation_file, img_dir, transform=None): 
        self.img_dir = img_dir
        self.transform = transform
        self.data_entries = [] 
        class_ids = []


        with open(annotation_file, 'r') as f: #use annotation file
            for line in f:
                
                if line.startswith("Error: "):
                    line = line[7:].strip()
                
                main_parts = line.strip().split('.jpg ') #edit label

                if len(main_parts) < 2: 
                    continue #skip 

                #reconstruct the image filename and labels
                img_path_raw = main_parts[0] + '.jpg'
                labels_raw = main_parts[1].strip() 
                label_parts = labels_raw.split(',')
                
                if len(label_parts) < 5:
                     print(f"Warning: Annotation format error: {line.strip()}")
                     continue
                
                try:
                    # ID CHECK
                    class_id = int(label_parts[-1]) 
                    img_name = os.path.basename(img_path_raw)
                    self.data_entries.append((img_name, class_id))
                    class_ids.append(class_id)
                    
                except (ValueError, IndexError):
                    print(f"Error: Could not parse class ID or image name from {line.strip()}")
                    continue #skip

        # Find number of classes
        if class_ids:
            self.num_classes = max(class_ids) + 1
        else:
            self.num_classes = 0

    def __len__(self):
        return len(self.data_entries)

    def __getitem__(self, idx):
        img_name, label = self.data_entries[idx]
        img_path = os.path.join(self.img_dir, img_name)
        
        # load images
        try:
            image = Image.open(img_path).convert('RGB')
        except FileNotFoundError:
            print(f"Error. Images has no. {img_path}.")
            return None

        if self.transform:
            image_tensor = self.transform(image)
        else:
            image_tensor = transforms.ToTensor()(image)
        
        label_tensor = torch.tensor(label, dtype=torch.long)
        
        return image_tensor, label_tensor

#main

if __name__ == '__main__':
    
    DATA_DIR_PATH = './dataset/' 
    ANNOTATION_FILE = os.path.join(DATA_DIR_PATH, 'train', '_annotations.txt')
    TRAIN_IMG_DIR = os.path.join(DATA_DIR_PATH, 'train') 

    BATCH_SIZE = 64
    NUM_EPOCHS = 10 
    
    # preprocessing
    train_transform = transforms.Compose([
        transforms.Resize((30, 30)), 
        transforms.ToTensor(), # normalized
    ])

    train_dataset = AnnotationDataset(
        annotation_file=ANNOTATION_FILE, 
        img_dir=TRAIN_IMG_DIR, 
        transform=train_transform
    )
    
    DATASET_NUM_CLASSES = train_dataset.num_classes 
    
    if DATASET_NUM_CLASSES == 0:
        print("Error. Label is not find.")
        exit()
    

    if DATASET_NUM_CLASSES != model.fc2.out_features:
        print(f"ERROR: Dataset class count ({DATASET_NUM_CLASSES}) does not match Model class count ({model.fc2.out_features})!")
        print(f"Please update NUM_CLASSES in data_nn.py to {DATASET_NUM_CLASSES} and restart.")
        exit()

    train_dataloader = DataLoader(train_dataset, batch_size=BATCH_SIZE, shuffle=True)
    
    print(f"Train is started")
    
    # train
    train_model(
        model=model, 
        dataloader=train_dataloader, 
        criterion=criterion, 
        optimizer=optimizer, 
        num_epochs=NUM_EPOCHS
    )

    # save
    MODEL_PATH = './models/simple_cnn_traffic_sign.pth'
    os.makedirs('./models', exist_ok=True)
    torch.save(model.state_dict(), MODEL_PATH) 
    print(f"\nModel saved to: {MODEL_PATH}")