.PHONY: run install clean

# Default target
all: run

# Run the server
run:
	@if [ ! -f .env ]; then \
		echo "Error: .env file not found. Please create one from .env.example"; \
		exit 1; \
	fi
	uvicorn main:app --reload

# Install dependencies
install:
	python3 -m venv venv
	. venv/bin/activate && pip install -r requirements.txt

# Clean up
clean:
	rm -rf __pycache__
	rm -rf venv
