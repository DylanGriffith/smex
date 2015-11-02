# Change API
1. Don't keep connection stored in global state, while simpler it actually
   makes things much less testable and much less flexible (eg. connecting to
   multiple rabbitmq instances) and also introduces a single point of failure
   that all processes will need to link to.
2. The API for receiving messages should be part of some genserver twist. You
   still need to setup the connection + channel in the `init` and subscribe
   yourself, however the messages get translated by a different `handle_cast`
   and cast back to this process as deserialized protobufs. You keep track of
   connection and channel in state. Again it may seem like this API is more
   fidlly to setup, but really it's much more fleixible as it's a pure
   GenServer and you can subscribe as much as you want. Translated messages and
   incorrect messages just have different `handle_cast` patterns. There is a
   default implementation for incorrect message types and it puts those on an
   error queue (how? needs the state).
