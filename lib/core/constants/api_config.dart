class ApiConfig {

  static const String baseUrl = "http://172.18.1.252/inventivo_backend/api";

  // AUTENTICACIÓN Y ROLES
  static const String registroPropietario = "$baseUrl/usuarios/registrar_propietario.php"; // Renombrado
  static const String login = "$baseUrl/usuarios/login.php";
  

  // Registro personal y Obtener personal
  static const String registroPersonal = "$baseUrl/usuarios/trabajador/registro_trabajador.php";
  //Modulo trabajador (Ahora llamado 'personal' o 'usuarios')
 static String obtenerPersonal(int idSede, {String? filtro}) { 
    String url = "$baseUrl/usuarios/trabajador/obtener_trabajadores.php?id_sede=$idSede";
    if (filtro != null && filtro.isNotEmpty) {
      url += "&filtro=$filtro"; 
    }
    return url;
  }
  static const String cambiarEstado = "$baseUrl/usuarios/trabajador/cambiar_estado.php";
  static const String eliminarTrabajador = "$baseUrl/usuarios/trabajador/eliminar_trabajador.php";
  static const String editarTrabajador = "$baseUrl/usuarios/trabajador/editar_trabajador.php";
  static const String obtenerPersonalEmpresa = "$baseUrl/usuarios/obtener_personal_empresa.php";


  //Modulo de insumos
  static const String registrarInsumo = "$baseUrl/insumos/registrar.php";
  static String listarInsumos(int idSede, {String? filtro}) {
    String url = "$baseUrl/insumos/listar.php?id_sede=$idSede";
    if (filtro != null && filtro.isNotEmpty) {
      url += "&filtro=${Uri.encodeComponent(filtro)}";
    }
    return url;
  }
  static const String editarInsumo = "$baseUrl/insumos/actualizar.php";
  static const String eliminarInsumo = "$baseUrl/insumos/eliminar.php"; 

  //Modulo de uso de insumos (requerirá migración a id_sede también)
  static const String registrarUsoInsumo = "$baseUrl/insumos/insumousado/registrar_actividad.php";
  static const String listarUsoInsumos = "$baseUrl/insumos/insumousado/listar_uso.php";

  //Modulo de Plantas (CRUD)
  static const String registrarPlantas = "$baseUrl/plantas/agregar.php";
  static String listarPlantas(int idSede, {String? filtro}) {
      String url = "$baseUrl/plantas/listar.php?id_sede=$idSede";
      if (filtro != null && filtro.isNotEmpty) {
        url += "&filtro=${Uri.encodeComponent(filtro)}";
      }
    return url;
  }
  static const String editarPlantas= "$baseUrl/plantas/actualizar.php";
  static const String eliminarPlantas= "$baseUrl/plantas/eliminar.php";

 //Modulo de Remisiones (Antes Facturas)
static const String registrarRemision = "$baseUrl/remisiones/agregar.php";
static String listarRemisiones(int idSede) => "$baseUrl/remisiones/listar.php?id_sede=$idSede";
static const String eliminarRemision = "$baseUrl/remisiones/eliminar.php";
static String verDetalleRemision(int idRemision) => "$baseUrl/remisiones/detalle.php?id_remision=$idRemision";
static String siguienteNumeroRemision(int idSede) => "$baseUrl/remisiones/siguiente_numero.php?id_sede=$idSede";

//AUDITORIA
static String listarAuditoria(int idEmpresa) => "$baseUrl/auditoria/listar.php?id_empresa=$idEmpresa";

//Chatbot
static String chatbotSearch(String plantName, int idEmpresa) => 
      "$baseUrl/public/chatbot_search.php?nombre=${Uri.encodeComponent(plantName)}&id_empresa=$idEmpresa";}