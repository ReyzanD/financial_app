# API Documentation

## Base URL
```
http://10.0.2.2:5000/api/v1
```

## Authentication
All API endpoints require JWT authentication via Bearer token in the Authorization header:
```
Authorization: Bearer <token>
```

## Endpoints

### Transactions

#### GET /transactions_232143
Get list of transactions with optional filters and pagination.

**Query Parameters:**
- `limit` (int, optional): Number of items per page (default: 10)
- `offset` (int, optional): Number of items to skip (default: 0)
- `type` (string, optional): Filter by type ('income', 'expense', 'transfer')
- `category_id` (string, optional): Filter by category ID
- `start_date` (string, optional): Start date in ISO format (YYYY-MM-DD)
- `end_date` (string, optional): End date in ISO format (YYYY-MM-DD)
- `search` (string, optional): Search in description and notes

**Response:**
```json
{
  "transactions": [
    {
      "id": "uuid",
      "amount": 100000,
      "type": "expense",
      "description": "Lunch",
      "category_id": "uuid",
      "category_name": "Food",
      "date": "2024-01-15T12:00:00Z",
      "payment_method": "cash",
      "location_name_232143": "Restaurant Name",
      "latitude_232143": -6.2088,
      "longitude_232143": 106.8456
    }
  ],
  "total": 100,
  "count": 10,
  "has_more": true,
  "limit": 10,
  "offset": 0
}
```

**Error Codes:**
- `401`: Unauthorized - Token expired or invalid
- `500`: Internal server error

#### POST /transactions_232143
Create a new transaction.

**Request Body:**
```json
{
  "amount": 100000,
  "type": "expense",
  "description": "Lunch",
  "category_id": "uuid",
  "date": "2024-01-15T12:00:00Z",
  "payment_method": "cash",
  "location_name_232143": "Restaurant Name",
  "latitude_232143": -6.2088,
  "longitude_232143": 106.8456,
  "notes_232143": "Optional notes"
}
```

**Response:**
```json
{
  "transaction": {
    "id": "uuid",
    "amount": 100000,
    "type": "expense",
    ...
  }
}
```

#### PUT /transactions_232143/:id
Update an existing transaction.

**Request Body:** Same as POST

#### DELETE /transactions_232143/:id
Delete a transaction.

**Response:**
```json
{
  "message": "Transaction deleted successfully"
}
```

### Budgets

#### GET /budgets
Get list of budgets.

**Response:**
```json
{
  "budgets": [
    {
      "id": "uuid",
      "category_id": "uuid",
      "amount": 1000000,
      "period": "monthly",
      "period_start": "2024-01-01",
      "alert_threshold": 80,
      "is_active": true
    }
  ]
}
```

#### POST /budgets
Create a new budget.

**Request Body:**
```json
{
  "category_id": "uuid",
  "amount": 1000000,
  "period": "monthly",
  "period_start": "2024-01-01",
  "alert_threshold": 80,
  "rollover_enabled": false,
  "is_active": true
}
```

### Categories

#### GET /categories
Get list of categories.

**Response:**
```json
{
  "categories": [
    {
      "id": "uuid",
      "name": "Food",
      "type": "expense",
      "icon": "restaurant",
      "color": "#FF5722"
    }
  ]
}
```

### Goals

#### GET /goals
Get list of financial goals.

**Response:**
```json
{
  "goals": [
    {
      "id": "uuid",
      "name": "Emergency Fund",
      "target_amount": 10000000,
      "current_amount": 5000000,
      "target_date": "2024-12-31",
      "type": "savings"
    }
  ]
}
```

## Error Response Format

All errors follow this format:
```json
{
  "error": "Error message",
  "code": "ERROR_CODE",
  "details": {}
}
```

## Common Error Codes

- `UNAUTHORIZED` (401): Authentication required or token expired
- `FORBIDDEN` (403): Insufficient permissions
- `NOT_FOUND` (404): Resource not found
- `VALIDATION_ERROR` (422): Invalid input data
- `INTERNAL_ERROR` (500): Server error

## Rate Limiting

- 60 requests per minute per endpoint
- 1000 requests per hour per endpoint

Rate limit headers:
```
X-RateLimit-Remaining: 59
X-RateLimit-Reset: 1609459200
```

