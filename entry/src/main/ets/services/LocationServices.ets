import { geoLocationManager } from '@kit.LocationKit';


export async function getUserStartLocation() {
  let locationRequest: geoLocationManager.LocationRequest = {
    priority: geoLocationManager.LocationRequestPriority.ACCURACY,
    timeInterval: 0,
    distanceInterval: 0,
    maxAccuracy: 0
  };
  let startLocation = await geoLocationManager.getCurrentLocation(locationRequest);
  return startLocation;
}