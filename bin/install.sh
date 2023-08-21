declare VENV_DIR=$(pwd)/.venv
if ! [ -d "$VENV_DIR" ]; then
    python3 -m venv $VENV_DIR
fi

source $VENV_DIR/bin/activate
pip install --upgrade pip
pip install pre-commit
pre-commit install
