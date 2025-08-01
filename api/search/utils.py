"""
Search utilities for fuzzy matching and text processing.
"""

import re
from typing import List, Tuple, Optional, Dict, Any
from difflib import SequenceMatcher
import math

def extract_years_from_text(text: str) -> List[int]:
    """
    Extract potential years from a text string.
    
    Args:
        text: Input text to search for years
        
    Returns:
        List of years found in the text (1900-2030 range)
    """
    if not text:
        return []
    
    # Look for 4-digit numbers that could be years
    year_pattern = r'\b(19[0-9]{2}|20[0-2][0-9]|2030)\b'
    matches = re.findall(year_pattern, text)
    return [int(year) for year in matches]

def normalize_serial_number(serial_number: str) -> str:
    """
    Normalize a serial number for exact matching by removing dashes and leading zeros.
    
    Args:
        serial_number: Input serial number
        
    Returns:
        Normalized serial number
    """
    if not serial_number:
        return ""
    
    # Remove dashes and spaces
    normalized = serial_number.replace('-', '').replace(' ', '')
    
    # Remove leading zeros (but keep at least one character)
    while len(normalized) > 1 and normalized.startswith('0'):
        normalized = normalized[1:]
    
    return normalized

def normalize_search_term(term: str) -> str:
    """
    Normalize a search term for consistent matching.
    
    Args:
        term: Input search term
        
    Returns:
        Normalized search term
    """
    if not term:
        return ""
    
    # Convert to lowercase and strip whitespace
    normalized = term.lower().strip()
    
    # Replace multiple spaces with single space
    normalized = re.sub(r'\s+', ' ', normalized)
    
    # Remove special characters but keep alphanumeric, spaces, and hyphens
    normalized = re.sub(r'[^a-z0-9\s\-]', '', normalized)
    
    return normalized

def split_search_terms(term: str) -> List[str]:
    """
    Split a search term into individual words for matching.
    
    Args:
        term: Input search term
        
    Returns:
        List of individual words
    """
    normalized = normalize_search_term(term)
    return [word for word in normalized.split() if len(word) > 0]

def calculate_similarity_score(text1: str, text2: str) -> float:
    """
    Calculate similarity score between two text strings.
    
    Args:
        text1: First text string
        text2: Second text string
        
    Returns:
        Similarity score between 0.0 and 1.0
    """
    if not text1 or not text2:
        return 0.0
    
    # Normalize both strings
    norm1 = normalize_search_term(text1)
    norm2 = normalize_search_term(text2)
    
    if norm1 == norm2:
        return 1.0
    
    # Use sequence matcher for similarity
    return SequenceMatcher(None, norm1, norm2).ratio()

def build_fuzzy_where_clause(search_terms: List[str], column_name: str, 
                           similarity_threshold: float = 0.3) -> Tuple[str, List[str]]:
    """
    Build a PostgreSQL WHERE clause for fuzzy text matching using trigrams.
    
    Args:
        search_terms: List of search terms to match
        column_name: Database column name to search
        similarity_threshold: Minimum similarity threshold
        
    Returns:
        Tuple of (WHERE clause, parameters for query)
    """
    if not search_terms:
        return "", []
    
    clauses = []
    params = []
    
    for term in search_terms:
        if len(term) >= 3:  # Trigram matching works best with 3+ characters
            # Use PostgreSQL trigram similarity
            clauses.append(f"similarity(LOWER({column_name}), LOWER(%s)) > %s")
            params.extend([term, similarity_threshold])
        else:
            # For short terms, use ILIKE pattern matching
            clauses.append(f"LOWER({column_name}) ILIKE LOWER(%s)")
            params.append(f"%{term}%")
    
    if clauses:
        return f"({' OR '.join(clauses)})", params
    return "", []

def build_multifield_search_clause(search_terms: List[str], fields: List[str], 
                                 similarity_threshold: float = 0.3) -> Tuple[str, List[str]]:
    """
    Build a WHERE clause that searches across multiple fields.
    
    Args:
        search_terms: List of search terms
        fields: List of field names to search
        similarity_threshold: Minimum similarity threshold
        
    Returns:
        Tuple of (WHERE clause, parameters)
    """
    if not search_terms or not fields:
        return "", []
    
    field_clauses = []
    all_params = []
    
    for field in fields:
        clause, params = build_fuzzy_where_clause(search_terms, field, similarity_threshold)
        if clause:
            field_clauses.append(clause)
            all_params.extend(params)
    
    if field_clauses:
        return f"({' OR '.join(field_clauses)})", all_params
    return "", []

def paginate_results(results: List[Dict[str, Any]], page: int, page_size: int, 
                    total_records: int) -> Dict[str, Any]:
    """
    Apply pagination to results and create pagination metadata.
    
    Args:
        results: List of result records
        page: Current page number (1-based)
        page_size: Number of records per page
        total_records: Total number of matching records
        
    Returns:
        Dict with paginated results and metadata
    """
    total_pages = math.ceil(total_records / page_size) if total_records > 0 else 0
    
    return {
        'data': results,
        'pagination': {
            'current_page': page,
            'page_size': page_size,
            'total_pages': total_pages,
            'total_records': total_records
        }
    }

def validate_pagination_params(page: Optional[int], page_size: Optional[int], 
                             max_page_size: int = 10) -> Tuple[int, int]:
    """
    Validate and normalize pagination parameters.
    
    Args:
        page: Requested page number
        page_size: Requested page size
        max_page_size: Maximum allowed page size
        
    Returns:
        Tuple of (validated_page, validated_page_size)
    """
    # Validate page number
    validated_page = max(1, page if page and page > 0 else 1)
    
    # Validate page size
    if page_size and page_size > 0:
        validated_page_size = min(page_size, max_page_size)
    else:
        validated_page_size = max_page_size
    
    return validated_page, validated_page_size