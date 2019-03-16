# frideos_core examples

### StreamedValue

```dart
// In the BLoC
final count = StreamedValue<int>(initialData: 0);

incrementCounter() {
  count.value += 2.0;
}

// View
ValueBuilder<int>(
  stream: bloc.count, // no need of the outStream getter with ValueBuilder
  builder: (context, snapshot) =>
    Text('Value: ${snapshot.data}'),
  noDataChild: Text('NO DATA'),
),
RaisedButton(
    color: buttonColor,
    child: Text('+'),
    onPressed: () {
      bloc.incrementCounter();
    },
),

// As an alternative:
//
// StreamedWidget<int>(
//    initialData: bloc.count.value
//    stream: bloc.count.outStream,
//    builder: (context, snapshot) => Text('Value: ${snapshot.data}'),
//    noDataChild: Text('NO DATA'),
//),
```


### StreamedTransformed

```dart
// In the BLoC class
final streamedKey = StreamedTransformed<String, int>();



// In the constructor of the BLoC class
streamedKey.setTransformer(validateKey);



// Validation (e.g. in the BLoC or in a mixin class)
final validateKey =
      StreamTransformer<String, int>.fromHandlers(handleData: (key, sink) {
    var k = int.tryParse(key);
    if (k != null) {
      sink.add(k);
    } else {
      sink.addError('The key must be an integer.');
    }
  });


// In the view:
StreamBuilder<int>(
            stream: bloc.streamedKey.outTransformed,
            builder: (context, snapshot) {
              return Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 20.0,
                    ),
                    child: TextField(
                      style: TextStyle(
                        fontSize: 18.0,
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Key:',
                        hintText: 'Insert an integer...',
                        errorText: snapshot.error,
                      ),
                      // To avoid the user could insert text use the TextInputType.number
                      // Here is commented to show the error msg.
                      //keyboardType: TextInputType.number,
                      onChanged: bloc.streamedKey.inStream,
                    ),
                  ),
                ],
              );
            }),
```

### StreamedList
e.g. adding an item:

```dart
 streamedList.addElement(item);
```

it is the same as:

```dart
  streamedList.value.add(item);
  streamedList.refresh();
```

From the StreamedList example:

```dart
  final streamedList = StreamedList<String>();


  // Add to the streamed list the string from the textfield
  addText() {
    streamedList.addElement(streamedText.value);

    // Or, as an alternative:
    // streamedList.value.add(streamedText.value);
    // streamedList.refresh(); // To refresh the stream with the new value
  }
```

### StreamedMap
e.g. adding a key/value pair:

```dart
  streamedMap.addKey(1, 'first');
```

it is the same as:

```dart
   streamedMap.value[1] = 'first';
   streamedList.refresh();
```

From the streamed map example:

```dart
  final streamedMap = StreamedMap<int, String>();


  // Add to the streamed map the key/value pair put by the user
  addText() {
    var key = int.parse(streamedKey.value);
    var value = streamedText.value;

    streamedMap.addKey(key, value);

    // Or, as an alternative:
    //streamedMap.value[key] = value;
    //streamedMap.refresh();
  }
```

### MemoryValue

```dart
final countMemory = MemoryValue<int>();

countMemory.value // current value
couneMemory.oldValue // previous value
```


### StreamedSender

1. Define an object that implements the `StreamedObject` interface in the blocB (e.g. a `StreamedValue`):

```dart
final receiverStr = StreamedValue<String>();
```

2. Define a `StreamedSender` in the blocA:

```dart
final tunnelSenderStr = StreamedSender<String>();
```

3. Set the receiver in the sender on the class the holds the instances of the blocs:

```dart
blocA.tunnelSenderStr.setReceiver(blocB.receiverStr);
```

4. To send data from blocA to blocB then:

```dart
tunnelSenderStr.send("Text from blocA to blocB");
```

### ListSender and MapSender

1. Define a `StreamedList` or `StreamedMap` object in the blocB

```dart
final receiverList = StreamedList<int>();
final receiverMap = StreamedMap<int, String>();
```

2. Define a `ListSender`/`MapSender` in the blocA

```dart
final tunnelList = ListSender<int>();
final tunnelMap = MapSender<int, String>();
```

3. Set the receiver in the sender on the class the holds the instances of the blocs

```dart
blocA.tunnelList.setReceiver(blocB.receiverList);
blocA.tunnelMap.setReceiver(blocB.receiverMap);
```

4. To send data from blocA to blocB then:

```dart
tunnelList.send(list);
tunnelMap.send(map);
```

### TimerObject

```dart
final timerObject = TimerObject();

startTimer() {
  timerObject.startTimer();
}

stopTimer() {
  timerObject.stopTimer();
}

getLapTime() {
  timerObject.getLapTime();
}

incrementCounter(Timer t) {
  counter.value += 2.0;
}

startPeriodic() {
   var interval = Duration(milliseconds: 1000);
   timerObject.startPeriodic(interval, incrementCounter);
}

```

### AnimatedObject

- #### In the BLoC:

```dart
// Initial value 0.5, updating interval 20 milliseconds
  final scaleAnimation =
      AnimatedObject<double>(initialValue: 0.5, interval: 20);


  final rotationAnimation =
      AnimatedObject<double>(initialValue: 0.5, interval: 20);

  start() {
    scaleAnimation.start(updateScale);
    rotationAnimation.start(updateRotation);
  }

  updateScale(Timer t) {
    scaleAnimation.value += 0.03;

    if (scaleAnimation.value > 8.0) {
      scaleAnimation.reset();
    }
  }

  updateRotation(Timer t) {
    rotationAnimation.value += 0.1;
  }


  stop() {
    scaleAnimation.stop();
    rotationAnimation.stop();
  }

  reset() {
    scaleAnimation.reset();
    rotationAnimation.reset();
  }
```

- #### In the view:

```dart
      Container(
          color: Colors.blueGrey[100],
          child: Column(
            children: <Widget>[
              Container(height: 20.0,),
               ValueBuilder<AnimatedStatus>(
                stream: bloc.scaleAnimation.status,
                builder: (context, snapshot) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      snapshot.data == AnimatedStatus.active
                          ? RaisedButton(
                              color: Colors.lightBlueAccent,
                              child: Text('Reset'),
                              onPressed: () {
                                bloc.reset();
                              })
                          : Container(),
                      snapshot.data == AnimatedStatus.stop
                          ? RaisedButton(
                              color: Colors.lightBlueAccent,
                              child: Text('Start'),
                              onPressed: () {
                                bloc.start();
                              })
                          : Container(),
                      snapshot.data == AnimatedStatus.active
                          ? RaisedButton(
                              color: Colors.lightBlueAccent,
                              child: Text('Stop'),
                              onPressed: () {
                                bloc.stop();
                              })
                          : Container(),
                    ],
                  );
                },
              ),
              Expanded(
                child: ValueBuilder<double>(
                    stream: bloc.scaleAnimation,
                    builder: (context, snapshot) {
                      return Transform.scale(
                          scale: snapshot.data,
                          // No need for StreamBuilder here, the widget
                          // is already updating
                          child: Transform.rotate(
                              angle: bloc.rotationAnimation.value,
                              // Same here
                              //
                              child: Transform(
                                  transform: Matrix4.rotationY(
                                      bloc.rotationAnimation.value),
                                  child: FlutterLogo())));
                    }),
              )
            ],
          ),
        ),
```

### StreamedMap example
This example shows how to use some classes of this library, and a comparison code without it. It is just a page with two textfields to add a key/value pair to a map. The map is then used to drive a ListView.builder showing all the pairs.


#### Common code
```dart
class Validators {
  final validateText =
      StreamTransformer<String, String>.fromHandlers(handleData: (str, sink) {
    if (str.isNotEmpty) {
      sink.add(str);
    } else {
      sink.addError('The text must not be empty.');
    }
  });

  final validateKey =
      StreamTransformer<String, int>.fromHandlers(handleData: (key, sink) {
    var k = int.tryParse(key);
    if (k != null) {
      sink.add(k);
    } else {
      sink.addError('The key must be an integer.');
    }
  });
}
```

1. ##### BLoC without this library

```dart
class StreamedMapCleanBloc extends BlocBase with Validators {
  StreamedMapCleanBloc() {
    print('-------StreamedMapClean BLOC--------');
  }

  final _map = BehaviorSubject<Map<int, String>>();
  Stream<Map<int, String>> get outMap => _map.stream;
  Function(Map<int, String> map) get inMap => _map.sink.add;
  final map = Map<int, String>();

  final _text = BehaviorSubject<String>();
  Stream<String> get outText => _text.stream;
  Stream<String> get outTextTransformed => _text.stream.transform(validateText);
  Function(String text) get inText => _text.sink.add;

  final _key = BehaviorSubject<String>();
  Stream<String> get outKey => _key.stream;
  Stream<int> get outKeyTransformed => _key.stream.transform(validateKey);
  Function(String) get inKey => _key.sink.add;

  Observable<bool> get isFilled => Observable.combineLatest2(
      outTextTransformed, outKeyTransformed, (a, b) => true);

  // Add to the streamed map the key/value pair put by the user
  addText() {
    var key = int.parse(_key.value);
    var value = _text.value;
    var streamMap = _map.value;

    if (streamMap != null) {
      map.addAll(streamMap);
    }

    map[key] = value;
    inMap(map);
  }

  dispose() {
    print('-------StreamedMapClean BLOC DISPOSE--------');

    _map.close();
    _text.close();
    _key.close();
  }
}
```

2. ##### With this library:

```dart
class StreamedMapBloc extends BlocBase with Validators {
  StreamedMapBloc() {
    print('-------StreamedMap BLOC--------');

    // Set the validation transformers for the textfields
    streamedText.setTransformer(validateText);    
    streamedKey.setTransformer(validateKey);
  }

  final streamedMap = StreamedMap<int, String>();
  final streamedText = StreamedTransformed<String, String>();
  final streamedKey = StreamedTransformed<String, int>();

  Observable<bool> get isFilled => Observable.combineLatest2(
      streamedText.outTransformed, streamedKey.outTransformed, (a, b) => true);

  // Add to the streamed map the key/value pair put by the user 
  addText() {
    var key = int.parse(streamedKey.value);
    var value = streamedText.value;

    streamedMap.addKey(key, value);

    // Or, as an alternative:
    //streamedMap.value[key] = value;
    //streamedMap.refresh();
  }

  dispose() {
    print('-------Streamed BLOC DISPOSE--------');
    streamedMap.dispose();
    streamedText.dispose();
    streamedKey.dispose();
  }
}
```

As you can see the code is more clean, easier to read and to mantain.


