import 'package:flutter/widgets.dart';

/// App-wide route observer, installed on the `MaterialApp`. `CityScreen`
/// subscribes as a `RouteAware` so it learns when the question route chain
/// above it pops — that is when it reads the block's result and either
/// re-shows the wheel, celebrates an opened site, or zooms back out.
final routeObserver = RouteObserver<PageRoute<dynamic>>();
