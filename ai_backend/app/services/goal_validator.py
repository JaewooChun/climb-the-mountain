import torch
import torch.nn as nn
import torch.optim as optim
import numpy as np
from sklearn.metrics.pairwise import cosine_similarity
from transformers import AutoTokenizer, AutoModel 
from ..data.financial_keywords import FINANCIAL_GOAL_KEYWORDS
from ..data.unrelated_keywords import UNRELATED_KEYWORDS
import re

class FinancialGoalClassifier(nn.Module):
    def __init__(self, input_dim=768, hidden_dim=128):
        super(FinancialGoalClassifier, self).__init__()
        self.classifier = nn.Sequential(
            nn.Linear(input_dim, hidden_dim),
            nn.ReLU(),
            nn.Dropout(0.3),
            nn.Linear(hidden_dim, 64),
            nn.ReLU(),
            nn.Dropout(0.3),
            nn.Linear(64, 1),
            nn.Sigmoid()
        )
    
    def forward(self, x):
        return self.classifier(x)

class GoalValidator:
    def __init__(self):
        self.model_name = "ProsusAI/finbert"
        self.tokenizer = AutoTokenizer.from_pretrained(self.model_name)
        self.model = AutoModel.from_pretrained(self.model_name)
        self.financial_embeddings = None
        self.unrelated_embeddings = None
        self.classifier = FinancialGoalClassifier()
        self.classifier_trained = False

        self.initialize_reference_embeddings()
        self.train_classifier()
    
    def initialize_reference_embeddings(self):
        """initialize reference embeddings for financial and unrelated keywords"""
        # Financial embeddings
        financial_embeds = []
        for keyword in FINANCIAL_GOAL_KEYWORDS:
            embedding = self.get_embedding(keyword)
            financial_embeds.append(embedding)
        self.financial_embeddings = np.array(financial_embeds)

        # Unrelated embeddings
        unrelated_embeds = []
        for keyword in UNRELATED_KEYWORDS:
            embedding = self.get_embedding(keyword)
            unrelated_embeds.append(embedding)
        self.unrelated_embeddings = np.array(unrelated_embeds)

        print("Financial and unrelated reference embeddings initialized.")
    
    def train_classifier(self):
        """Train the neural network classifier on the reference embeddings"""
        print("Training financial goal classifier...")
        
        # Prepare training data
        X_train = np.concatenate([self.financial_embeddings, self.unrelated_embeddings], axis=0)
        y_train = np.concatenate([
            np.ones(len(self.financial_embeddings)),  # Financial goals = 1
            np.zeros(len(self.unrelated_embeddings))  # Non-financial goals = 0
        ])
        
        # Convert to PyTorch tensors
        X_tensor = torch.FloatTensor(X_train)
        y_tensor = torch.FloatTensor(y_train).unsqueeze(1)
        
        # Training setup
        criterion = nn.BCELoss()
        optimizer = optim.Adam(self.classifier.parameters(), lr=0.001)
        
        # Training loop
        epochs = 600
        for epoch in range(epochs):
            optimizer.zero_grad()
            outputs = self.classifier(X_tensor)
            loss = criterion(outputs, y_tensor)
            loss.backward()
            optimizer.step()
            
            if epoch % 50 == 0:
                print(f"Epoch {epoch}, Loss: {loss.item():.4f}")
        
        self.classifier_trained = True
        print("Classifier training completed!")
    
    def get_embedding(self, text):
        """get embedding for a given text using the transformer model"""
        inputs = self.tokenizer(text, return_tensors="pt", truncation=True, padding=True)
        with torch.no_grad():
            outputs = self.model(**inputs)
            # Use CLS token (first token) for sentence representation, which is standard for BERT models
            embeddings = outputs.last_hidden_state[:, 0, :].squeeze().numpy()

        return embeddings

    def validate_goal(self, goal_text):
        """
        Validate if the goal is financially relevant using the trained neural network classifier

        Returns:
            - is_valid: Boolean indicating if goal is financial
            - confidence_score: Probability score from classifier
            - suggestions: List of improvement suggestions
        """
        # Check minimum word count requirement
        words = re.findall(r'\b\w+\b', goal_text.lower())
        if len(words) < 3:
            print(f"Goal '{goal_text}' rejected: must be at least 3 words long")
            return False, 0.0, ["Your goal must be at least 3 words long. Please provide a more descriptive financial goal."]
        
        if not self.classifier_trained:
            print("Warning: Classifier not trained, falling back to similarity comparison")
            return self.validate_goal_similarity(goal_text)
        
        # Get embedding for the input goal
        goal_embedding = self.get_embedding(goal_text)
        
        # Use the trained classifier
        self.classifier.eval()
        with torch.no_grad():
            embedding_tensor = torch.FloatTensor(goal_embedding).unsqueeze(0)
            prediction = self.classifier(embedding_tensor)
            confidence_score = float(prediction.item())
        
        # Goal is valid if classifier probability > 0.5
        is_valid = confidence_score > 0.5
        
        print(f"Goal '{goal_text}': classifier_confidence={confidence_score:.3f}, is_valid={is_valid}")

        suggestions = []
        if not is_valid:
            if confidence_score < 0.2:
                suggestions.append("Your goal seems unrelated to financial matters. Consider focusing on savings, investments, budgeting, or debt management.")
            elif confidence_score < 0.5:
                suggestions.append("Your goal could be more clearly financial. Try incorporating terms like 'save', 'invest', or 'budget'.")
            
        return is_valid, confidence_score, suggestions
    
    def validate_goal_similarity(self, goal_text):
        """Fallback method using similarity comparison"""
        goal_embedding = self.get_embedding(goal_text)

        # Normalize embeddings to prevent divide by zero errors
        goal_norm = np.linalg.norm(goal_embedding)
        if goal_norm == 0:
            print(f"Warning: Zero embedding for goal '{goal_text}'")
            return False, 0.0, ["Unable to process this goal. Please try a different phrasing."]
        
        goal_embedding = goal_embedding / goal_norm

        # Normalize reference embeddings
        financial_norms = np.linalg.norm(self.financial_embeddings, axis=1, keepdims=True)
        financial_norms[financial_norms == 0] = 1
        financial_embeddings_norm = self.financial_embeddings / financial_norms

        unrelated_norms = np.linalg.norm(self.unrelated_embeddings, axis=1, keepdims=True)
        unrelated_norms[unrelated_norms == 0] = 1
        unrelated_embeddings_norm = self.unrelated_embeddings / unrelated_norms

        # Calculate similarities
        financial_similarities = np.dot(financial_embeddings_norm, goal_embedding)
        max_financial_similarity = np.max(financial_similarities)

        unrelated_similarities = np.dot(unrelated_embeddings_norm, goal_embedding)
        max_unrelated_similarity = np.max(unrelated_similarities)

        is_valid = max_financial_similarity > max_unrelated_similarity
        confidence_score = float(max_financial_similarity)

        suggestions = []
        if not is_valid:
            if max_financial_similarity < 0.3:
                suggestions.append("Your goal seems unrelated to financial matters. Consider focusing on savings, investments, budgeting, or debt management.")
            else:
                suggestions.append("Your goal could be more clearly financial. Try incorporating terms like 'save', 'invest', or 'budget'.")
            
        return is_valid, confidence_score, suggestions

