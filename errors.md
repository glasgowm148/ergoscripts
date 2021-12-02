# Debug

These three errors appear most often, preventing a full sync.

# INFO

## akkaDeadLetter

```bash
[INFO] [akkaDeadLetter][12/01/2021 18:50:06.181] [ergoref-akka.actor.default-dispatcher-11] [akka://ergoref/system/IO-TCP] Message [akka.io.Tcp$Unbind$] from Actor[akka://ergoref/user/networkController#-1862066825] to Actor[akka://ergoref/system/IO-TCP#-676687972] was unhandled. [1] dead letters encountered. This logging can be turned off or adjusted with configuration settings 'akka.log-dead-letters' and 'akka.log-dead-letters-during-shutdown'.
```

# WARN

## None,None,None


```bash
11:44:18.642 WARN  [ergoref-api-dispatcher-9] o.e.n.ErgoReadersHolder - Got GetReaders request in state (None,None,None,None)
```

Usually I thought this error meant a corrupted database and would require a resync - but killing the port and restarting it seems to have solved 


## strange input

```bash
10:43:31.206 WARN  [ctor.default-dispatcher-8] o.e.l.ErgoStatsCollector - Stats collector got strange input: SemanticallySuccessfulModifier(Header({"extensionId":"6575e18217532b26d6358e229135443f2754497e2fc1806ee5fb02d1f968fcea","difficulty":"1956164329799680","votes":"000000","timestamp":1638441760616,"size":220,"stateRoot":"28c6a26306551d4d7461f6e23398cfd9bbc1450e18d20db55d6bcbb8e844853d17","height":632463,"nBits":117895967,"version":2,"id":"8b109b27fdf9c0bf94d469aafd411b3f88633a2acdd11ef3a16e7fe6a0fe8b4e","adProofsRoot":"35acb2d6b6e85adde91bb87bf603a337ec8a1dc71182f6fc7840c60e8c7b578d","transactionsRoot":"502e4b912b742a04e4c228d689ddde1299a6a659f4be2fced16c3bc387765e8e","extensionHash":"19e70bd3364b082051844a62228850c10cc8d6fdd683a5b292f33f8b648ec851","powSolutions":{"pk":"02a1f56716cb8df4feb9371437904b9125b82db939238cd7d948786db33de3139f","w":"0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798","n":"3d1fdb87ef7f1033","d":0},"adProofsId":"a61d7f2a13907280a8020684d39af34283d44509a40b2f516bee5d76f43faef1","transactionsId":"26eacbdf5d52bc9f5f6aca6018d534bc62096f2fd0cfe8b93294aecfad91e76f","parentId":"16a7789b85820b4ec514b13c55c552844d3ed015c2b134fba4623987ba5aa279"}))
```

# ERROR


## LOCK

```bash
12:31:13.928 ERROR [ctor.default-dispatcher-5] scorex.db.StoreRegistry - Failed to initialize storage: java.io.IOException: Unable to acquire lock on '/Users/m/Documents/ergo_node/.ergo/peers/LOCK'. Please check that directory /Users/m/Documents/ergo_node/.ergo/peers exists and is not used by some other active node
```

> Solution: kill -9 <pid>


## historyReader

```bash
10:40:32.953 ERROR [tor.default-dispatcher-10] o.e.n.ErgoNodeViewSynchronizer - historyReader not initialized when processing syncInfo
```


# Local Error

Missing an empty check - but unclear why this field suddenly goes empty. 


```
Traceback (most recent call last):
  File "<string>", line 1, in <module>
  File "/System/Library/Frameworks/Python.framework/Versions/2.7/lib/python2.7/json/__init__.py", line 291, in load
    **kw)
  File "/System/Library/Frameworks/Python.framework/Versions/2.7/lib/python2.7/json/__init__.py", line 339, in loads
    return _default_decoder.decode(s)
  File "/System/Library/Frameworks/Python.framework/Versions/2.7/lib/python2.7/json/decoder.py", line 364, in decode
    obj, end = self.raw_decode(s, idx=_w(s, 0).end())
  File "/System/Library/Frameworks/Python.framework/Versions/2.7/lib/python2.7/json/decoder.py", line 382, in raw_decode
    raise ValueError("No JSON object could be decoded")
ValueError: No JSON object could be decoded
./install.sh: line 160: let: API_HEIGHT=: syntax error: operand expected (error token is "=")
./install.sh: line 186: ( (= - 135877) * 100) / =   : syntax error: operand expected (error token is "= - 135877) * 100) / =   ")
```