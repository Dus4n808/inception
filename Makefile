NAME      := inception
COMPOSE   := docker compose -f srcs/docker-compose.yml
DATA_DIR  ?= $(HOME)/data
export DATA_PATH := $(DATA_DIR)

all: up

up:
	@mkdir -p $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress
	@$(COMPOSE) up -d --build

build:
	@$(COMPOSE) build

down:
	@$(COMPOSE) down

re: down up

logs:
	@$(COMPOSE) logs -f

ps:
	@$(COMPOSE) ps

clean: down

fclean: down
	@$(COMPOSE) down --rmi all --volumes --remove-orphans
	@rm -rf $(DATA_PATH)/mariadb $(DATA_PATH)/wordpress
  

.PHONY: all up down re clean fclean logs ps build

