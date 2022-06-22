
package ${YYAndroidPackageName};

import ${YYAndroidPackageName}.R;
import com.yoyogames.runner.RunnerJNILib;


import android.app.Activity;
import android.util.Log;
import android.content.Intent;

public class Olympus extends RunnerSocial
{
  public static Activity activity = null;
  public static Intent launchIntent = null;

  public void _olympus_android_init() { 
		Log.i("yoyo", "_olympus_android_init");
		activity = RunnerActivity.CurrentActivity;    
		launchIntent = activity.getIntent();    
    Log.i("yoyo", "launchIntent: " + launchIntent);
  }	

  public void _olympus_android_game_end(){
    activity.finish();
  }	
}