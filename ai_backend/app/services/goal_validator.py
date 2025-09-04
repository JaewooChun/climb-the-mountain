import torch
import numpy as np
from sklearn.metrics.pairwise import cosine_similarity
from transformers import AutoTokenizer, AutoModel 
from ..data.financial_keywords import FINANCIAL_GOAL_KEYWORDS

class GoalValidator:
    def __init__(self):
        self.model_name = "ProsusAI/finbert"
        self.tokenizer = AutoTokenizer.from_pretrained(self.model_name)
        self.model = AutoModel.from_pretrained(self.model_name)
        self.financial_embeddings = None

        self.initialize_reference_embeddings()
    
    def initialize_reference_embeddings(self):
        """initialize reference embeddings for valid and invalid goals"""
        financial_embeds = []
        for keyword in FINANCIAL_GOAL_KEYWORDS:
            embedding = self.get_embedding(keyword)
            financial_embeds.append(embedding)
        self.financial_embeddings = np.array(financial_embeds)

        print("Reference embeddings initialized.")
    
    def get_embedding(self, text):
        """get embedding for a given text using the transformer model"""
        inputs = self.tokenizer(text, return_tensors="pt", truncation=True, padding=True)
        with torch.no_grad():
            outputs = self.model(**inputs)
            embeddings = outputs.last_hidden_state.mean(dim=1).squeeze().numpy()

        return embeddings

    def validate_goal(self, goal_text):
        """
        Validate if the goal is financially relevant using FinBERT embeddings

        Returns:
            - is_valid: Boolean indicating if goal is financial
            - confidence_score: Similarity score to financial concepts
            - suggestions: List of improvement suggestions
        """
        goal_embedding = self.get_embedding(goal_text)

        #calculate similarity to financial embeddings
        similarities = cosine_similarity([goal_embedding], self.financial_embeddings)
        max_similarity = np.max(similarities)

        is_valid = max_similarity > 0.5  # threshold for financial relevance

        confidence_score = float(max_similarity)

        suggestions = []

        if not is_valid:
            if max_similarity < 0.3:
                suggestions.append("Your goal seems unrelated to financial matters. Consider focusing on savings, investments, budgeting, or debt management.")
            elif max_similarity < 0.5:
                suggestions.append("Your goal has some financial aspects but could be more specific. Try incorporating terms like 'save', 'invest', or 'budget'.")
            
        return is_valid, confidence_score, suggestions

