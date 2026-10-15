package com.suanran.strangers

import android.app.Application
import android.content.Context
import com.suanran.strangers.common.GlobalState

class FlClashApplication : Application() {
    override fun attachBaseContext(base: Context?) {
        super.attachBaseContext(base)
        GlobalState.init(this)
    }
}
