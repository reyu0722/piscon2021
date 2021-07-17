DB_HOST:=127.0.0.1
DB_PORT:=3306
DB_USER:=isucari
DB_PASS:=isucari
DB_NAME:=isucari

MYSQL_CMD:=mysql -h$(DB_HOST) -P$(DB_PORT) -u$(DB_USER) -p$(DB_PASS) $(DB_NAME)

NGX_LOG:=/tmp/access.log
MYSQL_LOG:=/tmp/slow-query.log

KATARU_CFG:=./kataribe.toml

SLACKCAT:=slackcat --tee --channel general
SLACKRAW:=slackcat --channel general 

PPROF:=go tool pprof -png -output pprof.png http://localhost:6060/debug/pprof/profile



PROJECT_ROOT:=/home/isucon/isucari
BUILD_DIR:=/home/isucon/isucari/webapp/go
BIN_NAME:=isucari

CA:=-o /dev/null -s -w "%{http_code}\n"

all: build

.PHONY: clean
clean:
	cd $(BUILD_DIR); \
	rm -rf $(BIN_NAME)

deps:
	cd $(BUILD_DIR); \
	go mod download

.PHONY: build
build:
	cd $(BUILD_DIR); \
	make isucari

.PHONY: restart
restart:
	sudo systemctl restart isucari.golang

.PHONY: test
test:
	curl localhost $(CA)

# ここから元から作ってるやつ
.PHONY: dev
dev: build 
	cd $(BUILD_DIR); \
	./$(BIN_NAME)

.PHONY: bench-dev
bench-dev: commit before slow-on dev

.PHONY: bench
bench: commit before slow-on build restart

.PHONY: maji
bench: commit before build restart

.PHONY: anal
anal: slow kataru

.PHONY: commit
commit:
	cd $(PROJECT_ROOT); \
	git add .; \
	@read -p "変更点は: " message; \
	git commit --allow-empty -m $$message

.PHONY: before
before:
	$(eval when := $(shell date "+%s"))
	mkdir -p ~/logs/$(when)
	@if [ -f $(NGX_LOG) ]; then \
		sudo mv -f $(NGX_LOG) ~/logs/$(when)/ ; \
	fi
	@if [ -f $(MYSQL_LOG) ]; then \
		sudo mv -f $(MYSQL_LOG) ~/logs/$(when)/ ; \
	fi
	sudo systemctl restart nginx
	sudo systemctl restart mysql

.PHONY: slow
slow: 
	sudo pt-query-digest $(MYSQL_LOG) | $(SLACKCAT)

.PHONY: kataru
kataru:
	sudo cat $(NGX_LOG) | kataribe -f ./kataribe.toml | $(SLACKCAT)

.PHONY: pprof
pprof:
	$(PPROF)
	$(SLACKRAW) -n pprof.png ./pprof.png

.PHONY: slow-on
slow-on:
	$(MYSQL_CMD) -e "set global slow_query_log_file = '$(MYSQL_LOG)'; set global long_query_time = 0; set global slow_query_log = ON;"

.PHONY: slow-off
slow-off:
	$(MYSQL_CMD) -e "set global slow_query_log = OFF;"

.PHONY: setup
setup:
	sudo apt update
	sudo apt upgrade -y
	git config --global user.email "ka15sugar@gmail.com"
	git config --global user.name "reyu"
	mkdir ~/bin -p
	go get -u github.com/matsuu/kataribe
	kataribe -generate
	sudo apt install -y percona-toolkit dstat
	curl -Lo slackcat https://github.com/bcicen/slackcat/releases/download/1.7.2/slackcat-1.7.2-$(uname -s)-amd64
	sudo mv slackcat /usr/local/bin/
	sudo chmod +x /usr/local/bin/slackcat
	slackcat --configure