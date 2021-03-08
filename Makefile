.PHONY: ps ps_test erl all test clean

all: ps

ps:
	spago build

ps_test:
	spago --config test.dhall build

erl:
	mkdir -p ebin
	erlc -o ebin/ output/*/*.erl

clean:
	rm -rf ebin output src/compiled_ps
