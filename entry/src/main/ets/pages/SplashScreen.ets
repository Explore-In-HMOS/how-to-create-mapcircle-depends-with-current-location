import { abilityAccessCtrl, bundleManager, common, PermissionRequestResult, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { getUserStartLocation } from '../services/LocationServices';
import { getGlobalContext } from '../entryability/EntryAbility';

@Entry
@Component
struct SplashScreen {

  private mapOptions?: mapCommon.MapOptions;
  private context: common.UIAbilityContext = getGlobalContext();
  @Provide pathStack: NavPathStack = new NavPathStack()

  async checkPermissions() {
    const permissions: Array<Permissions> = ['ohos.permission.LOCATION', 'ohos.permission.APPROXIMATELY_LOCATION', 'ohos.permission.LOCATION_IN_BACKGROUND'];
    let allGranted = true;
    for (let permission of permissions) {
      let grantStatus: abilityAccessCtrl.GrantStatus = await this.checkAccessToken(permission);
      if (grantStatus !== abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        allGranted = false;
        break;
      }
    }

    if (allGranted) {
      await this.handleGrantedPermissions();
    } else {
      this.requestPermissions();
    }
  }

  async handleGrantedPermissions() {
    try {
      let location = await getUserStartLocation();
      this.mapOptions = {
        position: {
          target: {
            latitude: location.latitude,
            longitude: location.longitude
          },
          zoom: 10
        }
      };
    } catch (error) {
      console.error('Location error:', error);
      this.mapOptions = {
        position: {
          target: {
            latitude: 39,
            longitude: 116
          },
          zoom: 10
        }
      };
    }

    this.pathStack.pushPathByName('Index', this.mapOptions)

  }

  requestPermissions(): void {
    let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    atManager.requestPermissionsFromUser(this.context, ['ohos.permission.LOCATION', 'ohos.permission.APPROXIMATELY_LOCATION'])
      .then((data: PermissionRequestResult) => {

        this.checkPermissionsAfterRequest();
      })
      .catch((err: BusinessError) => {
        console.error(`Failed to request permissions from user. Code is ${err.code}, message is ${err.message}`);
        this.navigateWithDefaultLocation();
      });
  }

  async checkPermissionsAfterRequest() {
    const permissions: Array<Permissions> = ['ohos.permission.LOCATION', 'ohos.permission.APPROXIMATELY_LOCATION'];
    let allGranted = true;

    for (let permission of permissions) {
      let grantStatus: abilityAccessCtrl.GrantStatus = await this.checkAccessToken(permission);
      if (grantStatus !== abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        allGranted = false;
        break;
      }
    }

    if (allGranted) {
      await this.handleGrantedPermissions();
    } else {
      this.navigateWithDefaultLocation();
    }
  }

  navigateWithDefaultLocation() {
    this.mapOptions = {
      position: {
        target: {
          latitude: 39,
          longitude: 116
        },
        zoom: 10
      }
    };

    this.pathStack.pushPathByName('Index', this.mapOptions)
  }

  async checkAccessToken(permission: Permissions): Promise<abilityAccessCtrl.GrantStatus> {
    try {
      let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
      let grantStatus: abilityAccessCtrl.GrantStatus = abilityAccessCtrl.GrantStatus.PERMISSION_DENIED;

      let bundleInfo: bundleManager.BundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.
      BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      console.info('Succeeded in getting Bundle.');
      let appInfo: bundleManager.ApplicationInfo = bundleInfo.appInfo;
      let tokenId: number = appInfo.accessTokenId;

      grantStatus = await atManager.checkAccessToken(tokenId, permission);
      console.info('Succeeded in checking access token.');
      return grantStatus;
    } catch (error) {
      console.error('Error checking access token:', error);
      return abilityAccessCtrl.GrantStatus.PERMISSION_DENIED;
    }
  }

  aboutToAppear(): void {
    this.checkPermissions();
  }

  build() {
    Navigation(this.pathStack) {
      Stack() {
        LoadingProgress()
      }
      .height('100%')
      .width('100%')
    }
    .mode(NavigationMode.Stack)
  }
}