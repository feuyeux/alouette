#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>
#include <cstring>

#define ALOUETTE_LIB_TTS_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), alouette_lib_tts_plugin_get_type(), \
                             AlouetteLibTtsPlugin))

struct _AlouetteLibTtsPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(AlouetteLibTtsPlugin, alouette_lib_tts_plugin, g_object_get_type())

static void alouette_lib_tts_plugin_handle_method_call(
    AlouetteLibTtsPlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar* method = fl_method_call_get_name(method_call);

  if (strcmp(method, "isEdgeTTSAvailable") == 0) {
    // Check if edge-tts is available by trying to run 'edge-tts --version'
    int exit_status = system("which edge-tts > /dev/null 2>&1");
    g_autoptr(FlValue) result = fl_value_new_bool(exit_status == 0);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else if (strcmp(method, "getAvailableTTSEngines") == 0) {
    g_autoptr(FlValue) result = fl_value_new_list();
    // Check for available TTS engines
    if (system("which edge-tts > /dev/null 2>&1") == 0) {
      fl_value_append(result, fl_value_new_string("edge-tts"));
    }
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else if (strcmp(method, "getPlatformVersion") == 0) {
    struct utsname uname_data = {};
    uname(&uname_data);
    g_autofree gchar* version = g_strdup_printf("Linux %s", uname_data.release);
    g_autoptr(FlValue) result = fl_value_new_string(version);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

static void alouette_lib_tts_plugin_class_init(AlouetteLibTtsPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = alouette_lib_tts_plugin_dispose;
}

static void alouette_lib_tts_plugin_init(AlouetteLibTtsPlugin* self) {}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                          gpointer user_data) {
  AlouetteLibTtsPlugin* plugin = ALOUETTE_LIB_TTS_PLUGIN(user_data);
  alouette_lib_tts_plugin_handle_method_call(plugin, method_call);
}

void alouette_lib_tts_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  AlouetteLibTtsPlugin* plugin = ALOUETTE_LIB_TTS_PLUGIN(
      g_object_new(alouette_lib_tts_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                           "alouette_tts",
                           FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                          g_object_ref(plugin),
                                          g_object_unref);

  g_object_unref(plugin);
}