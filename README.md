# tl-types

Implementation of basic TL Language Types including constructors.
Constructors are interpreted at runtime instead of "building" a file with defintions.

```nim
import pkg/tltypes
    
echo tl("invokeAfterMsg", {"msg_id": 134643'u64, query: initTLConstructor("auth.logOut")})
```    

## Installing
This library is automatically installed with Nimgram (since it is a dependency), you can also install it manually using Nimble:


    nimble install https://github.com/nimgram/tl-types
