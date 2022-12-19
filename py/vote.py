import requests
import os

os.system('cls' if os.name == 'nt' else 'clear')

print("Ergo Mainnet EIP27 Vote Count")

url = "https://api.ergoplatform.com/api/v1/blocks?limit=1"
chainData = requests.get(url).json()
height = chainData["total"]
epoch = chainData["items"][0]["epoch"]
blocksInEpoch = height % 1024
blocksUntilNewEpoch = 1024 - blocksInEpoch

print("Chain Height:", height)
print("Epoch Number:", epoch)
print("Blocks In Epoch:", blocksInEpoch)
print("Blocks Until New Epoch:", blocksUntilNewEpoch)
print("Epoch Completion: " + str((blocksInEpoch / 1024) * 100) + "%")

votesYes = 0
votesNo = 0

while (blocksInEpoch > 0):
    url = ""
    if blocksInEpoch >= 500:
        url = "https://api.ergoplatform.com/api/v1/blocks/?limit=500&offset=0"
        blocksInEpoch -= 500
    else:
        url = "https://api.ergoplatform.com/api/v1/blocks/?limit=" + str(blocksInEpoch) + "&offset=0"
        blocksInEpoch -= blocksInEpoch
    blockData = requests.get(url).json()["items"]
    for i in blockData:
        id = i["id"]
        url = "https://api.ergoplatform.com/api/v1/blocks/" + id
        blockByIdData = requests.get(url).json()
        vote = blockByIdData["block"]["header"]["votes"]
        if vote[0] == 8:
            votesYes += 1
        else:
            votesNo += 1

print("\nVote Data")
print("Votes Needed: 888\n")
print("Votes Yes:", votesYes)
print("Votes No:", votesNo)
print("Percent Yes: " + str((votesYes / (votesYes + votesNo) * 100)) + "%")