import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback} from '@kit.BasicServicesKit';
import { router } from '@kit.ArkUI';
import { geoLocationManager } from '@kit.LocationKit';

@Entry
@Component
struct Index {

  private mapOptions: mapCommon.MapOptions | null = null;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapController?: map.MapComponentController;
  private mapEventManager?: map.MapEventManager;
  @State currentLocation: geoLocationManager.Location | null = null;
  private locationRequest: geoLocationManager.LocationRequest = {
    priority: geoLocationManager.LocationRequestPriority.ACCURACY,
    timeInterval: 0,
    distanceInterval: 0,
    maxAccuracy: 0
  };
  private locationChangeCallback?: (location: geoLocationManager.Location) => void;
  private mapCircle?: map.MapCircle;

  aboutToAppear(): void {
    const params = router.getParams() as mapCommon.MapOptions
    if(params) {
      this.mapOptions = params
    }

    this.locationChangeCallback = (location: geoLocationManager.Location) => {
      this.currentLocation = location;
      this.centerMapOnLocation(location);
      this.updateCirclePosition(location);
    };

    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController;
        this.mapEventManager = this.mapController.getEventManager();
        this.mapController.setMyLocationEnabled(true);
        this.mapController.setMyLocationControlsEnabled(true);

        let mapCircleOptions: mapCommon.MapCircleOptions = {
          center: {
            latitude: this.mapOptions!.position.target.latitude,
            longitude: this.mapOptions!.position.target.longitude
          },
          radius: 100,
          clickable: true,
          fillColor: 0xFFFFC100,
          strokeColor: 0xFFFF0000,
          strokeWidth: 10,
          visible: true,
          zIndex: 5
        }

        this.mapCircle = await this.mapController.addCircle(mapCircleOptions);
        this.startLocationUpdates();

        let callback = () => {
          if (this.currentLocation) {
            this.centerMapOnLocation(this.currentLocation);
          }
        }
        this.mapEventManager.on("mapLoad", callback);
      } else {
        console.error(`Failed to initialize the map. Code: ${err.code}; message: ${err.message}`);
      }
    };
  }

  private centerMapOnLocation(location: geoLocationManager.Location) {
    if (this.mapController) {
      const cameraPosition: mapCommon.CameraPosition = {
        target: {
          latitude: location.latitude,
          longitude: location.longitude,
        },
        zoom: 15,
        tilt: 0,
        bearing: 0
      };

      let cameraUpdate = map.newCameraPosition(cameraPosition);
      this.mapController.animateCamera(cameraUpdate, 1000);
    }
  }

  private async updateCirclePosition(location: geoLocationManager.Location) {
    if(this.mapController) {
      if (this.mapCircle) {
        this.mapCircle.remove();
      }

      let mapCircleOptions: mapCommon.MapCircleOptions = {
        center: {
          latitude: location.latitude,
          longitude: location.longitude
        },
        radius: 100,
        clickable: true,
        fillColor: 0xFFFFC100,
        strokeColor: 0xFFFF0000,
        strokeWidth: 10,
        visible: true,
        zIndex: 15
      }
      this.mapCircle = await this.mapController.addCircle(mapCircleOptions);
    }
  }

  private startLocationUpdates() {
    try {
      geoLocationManager.on('locationChange', this.locationRequest, this.locationChangeCallback!);
    } catch (error) {
      console.error('Location updates error:', error);
    }
  }

  aboutToDisappear(): void {
    if (this.locationChangeCallback) {
      geoLocationManager.off('locationChange', this.locationChangeCallback);
    }
  }

  build() {
    Stack() {
      MapComponent({ mapOptions: this.mapOptions!, mapCallback: this.callback }).width('100%').height('100%');
    }.height('100%')
  }
}