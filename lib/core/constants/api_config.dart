class ApiConfig {

  static const String baseUrl = "http://192.168.101.25/inventivo_backend/api";
  static const String registroAdmin = "$baseUrl/usuarios/registrar.php";
  static const String login = "$baseUrl/usuarios/login.php";

  //Modulo trabajador
  static const String registroTrabajador = "$baseUrl/usuarios/trabajador/registro_trabajador.php";
  static String obtenerTrabajadores(int idEmpresa) =>
      "$baseUrl/usuarios/trabajador/obtener_trabajadores.php?id_empresa=$idEmpresa";
  static const String cambiarEstado = "$baseUrl/usuarios/trabajador/cambiar_estado.php";
  static const String eliminarTrabajador = "$baseUrl/usuarios/trabajador/eliminar_trabajador.php";

  //Modulo de insumos
  static const String registrarInsumo = "$baseUrl/insumos/registrar.php";
  static const String listarInsumos = "$baseUrl/insumos/listar.php";
  static const String editarInsumo = "$baseUrl/insumos/actualizar.php";
  static const String buscarInsumo = "$baseUrl/insumos/buscar.php";

  //Modulo de Plantas (CRUD)
  static const String registrarPlantas = "$baseUrl/plantas/agregar.php";
  static const String listarPlantas = "$baseUrl/plantas/listar.php";
  static const String editarPlantas= "$baseUrl/plantas/actualizar.php";
  static const String eliminarPlantas= "$baseUrl/plantas/eliminar.php";
}