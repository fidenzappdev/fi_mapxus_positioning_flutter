## 0.0.1

* TODO: Describe initial release.

## 1.0.1

* Improved the service stop function and other related functions

## 1.0.7

* Added the checkSensorStatus method to retrieve the availability status of the required sensors for the Mapxus service.

## 1.0.9

* Added Foreground Service Feature

## 1.0.10

* Foreground service now waits for network connectivity before starting positioning, and retries automatically once a genuine offline start failure is recovered from.
* Fixed a bug where the foreground service would repeatedly restart positioning during normal indoor/outdoor signal transitions even while online.
