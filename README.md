# BufferOutputStreamToInputStream
Enables to have an Buffered output stream, linked to to an input stream... this is useful when testing, or when you need to simulate an input stream, that is refilled with local data on an event basis


```

// initialize
self.bufferWriter = [[BufferOutputStreamToInputStream alloc] init];
[self.bufferWriter openOutputStream];

// later you want to set the delegate of the inputStream and shedule it in runloop
// remember, you are responsible for the inputStream, the outputStream is taken care off;)
self.bufferWriter.inputStream.delegate = self;
[self.bufferWriter.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
[self.bufferWriter.inputStream open]

// fill with data when desired on some event      
[self.bufferWriter addDataToBuffer:someData];

```
