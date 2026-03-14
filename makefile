.PHONY: install kernel freeze clean

install:
	python -m pip install --upgrade pip setuptools wheel
	pip install -r requirements.txt

kernel:
	python -m ipykernel install --user --name econ580-thesis --display-name "Python (econ580-thesis)"

freeze:
	pip freeze > requirements.txt

clean:
	find . -type d -name "__pycache__" -prune -exec rm -rf {} +
	find . -type d -name ".ipynb_checkpoints" -prune -exec rm -rf {} +
