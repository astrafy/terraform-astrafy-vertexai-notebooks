.PHONY: install 
install:
	@echo "installing the requirements..."
	@chmod +x ./bin/install.sh
	@bash ./bin/install.sh
	@echo "requirements installed"
