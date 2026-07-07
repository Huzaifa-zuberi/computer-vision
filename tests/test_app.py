import pytest
from app import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_index_page(client):
    rv = client.get('/')
    assert rv.status_code == 200

def test_upload_page(client):
    rv = client.get('/upload')
    assert rv.status_code == 200

def test_fines_page(client):
    rv = client.get('/fines')
    assert rv.status_code == 200
