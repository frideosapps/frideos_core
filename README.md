# frideos_core [![pub package](https://img.shields.io/pub/v/frideos_core.svg)](https://pub.dartlang.org/packages/frideos_core)

A library for streams, BLoC pattern, tunnel pattern, timing and animations. Core of the following packages:
- [frideos](https://pub.dartlang.org/packages/frideos)
- [frideos_light](https://pub.dartlang.org/packages/frideos_light)
- [frideos_kvprx](https://pub.dartlang.org/packages/frideos_kvprx) 

#### [Classes for streams and BLoC pattern](#streams-and-bloc-pattern):

- StreamedValue
- StreamedTransformed
- StreamedList
- StreamedMap
- MemoryValue
- HistoryObject
- StreamedSender

#### [Classes for tunnel pattern](#tunnel-pattern)
- StreamedSender
- ListSender 
- MapSender

#### [Classes for animations and timing](#animations-and-timing)

- TimerObject
- AnimatedObject
- StagedObject
- StagedWidget


### Dependencies

- [RxDart](https://pub.dartlang.org/packages/rxdart)


## Streams and BLoC pattern

Utility classes to work with streams and BLoC pattern.

This example (you can find it in the [frideos_examples](https://github.com/frideosapps/frideos_examples) repository) shows how to use some classes of this library, and a comparison code without it. It is just a page with two textfields to add a key/value pair to a map. The map is then used to drive a `ListView.builder` showing all the pairs.

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
    final k = int.tryParse(key);
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
  void addText() {
    final key = int.parse(_key.value);
    final value = _text.value;
    final streamMap = _map.value;

    if (streamMap != null) {
      map.addAll(streamMap);
    }

    map[key] = value;
    inMap(map);
  }

  @override
  void dispose() {
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

    // Activate the debug console messages on disposing
    streamedMap.debugMode();
    streamedText.debugMode();
    streamedKey.debugMode();
  }

  final streamedMap = StreamedMap<int, String>(initialData: {});
  final streamedText = StreamedTransformed<String, String>();
  final streamedKey = StreamedTransformed<String, int>();

  Observable<bool> get isFilled => Observable.combineLatest2(
      streamedText.outTransformed, streamedKey.outTransformed, (a, b) => true);

  // Add to the streamed map the key/value pair put by the user
  void addText() {
    final key = int.parse(streamedKey.value);
    final value = streamedText.value;

    streamedMap.addKey(key, value);

    // Or, as an alternative:
    //streamedMap.value[key] = value;
    //streamedMap.refresh();
  }

  @override
  void dispose() {
    print('-------StreamedMap BLOC DISPOSE--------');
    streamedMap.dispose();
    streamedText.dispose();
    streamedKey.dispose();
  }
}
```

As you can see the code is more clean, easier to read and to mantain.

### StreamedValue

It's the simplest class that implements the `StreamedObject` interface.

Every time a new value is set, this is compared to the oldest one and if it is different, it is sent to stream. Used in tandem with `ValueBuilder` it automatically triggers the rebuild of the widgets returned by its builder.

So for example, instead of:

```dart
counter += 1;
stream.sink.add(counter);
```

It becomes just:

```dart
counter.value += 1;
```

It can be used even with `StreamedWidget` and `StreamBuilder` by using its stream getter `outStream`.

N.B. when the type is not a basic type (e.g int, double, String etc.) and the value of a property of the object is changed, it is necessary to call the `refresh` method to update the stream.

#### Usage

```dart
// In the BLoC
final count = StreamedValue<int>(initialData: 0);

incrementCounter() {
  count.value += 2.0;
}

// View
ValueBuilder<int>(
  streamed: bloc.count, // no need of the outStream getter with ValueBuilder
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
//    stream: bloc.count.outStream,
//    builder: (context, snapshot) => Text('Value: ${snapshot.data}'),
//    noDataChild: Text('NO DATA'),
//),
```

On update the `timesUpdated` increases showing how many times the value has been updated.

N.B. For collections use `StreamedList` and `StreamedMap` instead.

### StreamedTransformed

A particular class the implement the `StreamedObject` interface, to use when there is the need of a `StreamTransformer` (e.g. stream transformation, validation of input
fields, etc.).

#### Usage

From the StreamedMap example:

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

This class has been created to work with lists. It works like `StreamedValue`.

To modify the list (e.g. adding items) and update the stream automatically
use these methods:

- `AddAll`
- `addElement`
- `clear`
- `removeAt`
- `removeElement`
- `replace`
- `replaceAt`

For other direct actions on the list, to update the stream call
the `refresh` method instead.

#### Usage

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

This class has been created to work with maps, it works like `StreamedList`.

To modify the list (e.g. adding items) and update the stream automatically
use these methods:

- `addKey`
- `removeKey`
- `clear`

For other direct actions on the map, to update the stream call
the `refresh` method instead.

#### Usage

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

The `MemoryValue` has a property to preserve the previous value. The setter checks for the new value, if it is different from the one already stored, this one is given `oldValue` before storing and streaming the new one.

#### Usage

```dart
final countMemory = MemoryValue<int>();

countMemory.value // current value
couneMemory.oldValue // previous value
```

## HistoryObject

Extends the `MemoryValue` class, adding a `StreamedList`. Useful when it is need to store a value in a list.

```dart
final countHistory = HistoryObject<int>();

incrementCounterHistory() {
  countHistory.value++;
}

saveToHistory() {
  countHistory.saveValue();
}
```

## Tunnel pattern

Easy pattern to send data from one BLoC to another one.

### StreamedSender

Used to make a one-way tunnel beetween two blocs (from blocA to a StremedValue on blocB).

#### Usage

1. #### Define an object that implements the `StreamedObject` interface in the blocB (e.g. a `StreamedValue`):

```dart
final receiverStr = StreamedValue<String>();
```

2. #### Define a `StreamedSender` in the blocA:

```dart
final tunnelSenderStr = StreamedSender<String>();
```

3. #### Set the receiver in the sender on the class the holds the instances of the blocs:

```dart
blocA.tunnelSenderStr.setReceiver(blocB.receiverStr);
```

4. #### To send data from blocA to blocB then:

```dart
tunnelSenderStr.send("Text from blocA to blocB");
```

## ListSender and MapSender

Like the StreamedSender, but used with collections.

#### Usage

1. #### Define a `StreamedList` or `StreamedMap` object in the blocB

```dart
final receiverList = StreamedList<int>();
final receiverMap = StreamedMap<int, String>();
```

2. #### Define a `ListSender`/`MapSender` in the blocA

```dart
final tunnelList = ListSender<int>();
final tunnelMap = MapSender<int, String>();
```

3. #### Set the receiver in the sender on the class the holds the instances of the blocs

```dart
blocA.tunnelList.setReceiver(blocB.receiverList);
blocA.tunnelMap.setReceiver(blocB.receiverMap);
```

4. #### To send data from blocA to blocB then:

```dart
tunnelList.send(list);
tunnelMap.send(map);
```

## Animations and timing

### TimerObject

An object that embeds a timer and a stopwatch.

#### Usage

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

This class is used to update a value over a period of time. Useful to handle animations using the BLoC pattern.

From the AnimatedObject example of the [frideos_examples](https://github.com/frideosapps/frideos_examples):

![AnimatedObject](https://i.imgur.com/10nfh0R.gif)

#### Usage

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
                streamed: bloc.scaleAnimation.status,
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
                    streamed: bloc.scaleAnimation,
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