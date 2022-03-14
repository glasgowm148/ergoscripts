
> Note : Work-in-progress.

# Features

- Downloads latest .jar file
- Prompts and sets API key
- Track progress by percentage in CLI
- Set config specific to platform (Unix/Win/Pi)
- Logs & attempts to solve common problems.

![CLI](/run.png)


# Getting Started

Tested primarily on OSX/Pi

```
bash -c "$(curl -s https://node.phenotype.dev)"
```

## Raspberry Pi

This assumes a clean device.

### Prepare installation
```
sudo apt update && sudo apt upgrade -y
sudo apt install default-jdk git lsof -y
```

### Clone the repo
```
git clone https://github.com/glasgowm148/ergoscripts
```

### Execute script
```
cd ergoscripts
bash -c "$(curl -s https://node.phenotype.dev)"
```

You'll need to 1) enter a password and 2) determine if you want to launch on mainnet or testnet.


# Headless

The following section is for developers who are running a headless setup and want to interface with the Ergo node through the command line. 

We only provide a sample here but you can find more details in the [Swagger API docs](https://docs.ergoplatform.com/node/swagger/#main-methods).

### Validate sync

Need to check if everything is working as intended where the `headersHeight` value should increase in value over time.

```
curl http://127.0.0.1:9053/info
```

### Initialize wallet

This will return your 15 word mnemonic seed phrase.

```
curl -X POST "http://127.0.0.1:9053/wallet/init" -H "accept: application/json" -H "api_key: hello" -H "Content-Type: application/json" -d "{\"pass\":\"string\",\"mnemonicPass\":\"\"}"
```

### Unlock wallet

Call this before sending a transaction and only needs to be executed once in awhile.

```
curl -X POST "http://localhost:9053/wallet/unlock" -H "accept: application/json" -H "api_key: hello" -H "Content-Type: application/json" -d "{\"pass\":\"string\"}"
```

### List all addresses
```
curl -X GET "http://127.0.0.1:9053/wallet/addresses" -H "accept: application/json" -H "api_key: hello"
```

# References

- [1](https://stackoverflow.com/questions/3466166/how-to-check-if-running-in-cygwin-mac-or-linux)
- [Grep -P no longer works](https://stackoverflow.com/questions/16658333/grep-p-no-longer-works-how-can-i-rewrite-my-searches)




