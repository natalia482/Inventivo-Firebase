class ApiConfig {

  static const String baseUrl = "http://192.168.101.25/inventivo_backend/api";
  static const String registroAdmin = "$baseUrl/usuarios/registrar.php";
  static const String login = "$baseUrl/usuarios/login.php";

  //Modulo trabajador
  //registrar trabajador
  static const String registroTrabajador = "$baseUrl/usuarios/trabajador/registro_trabajador.php";
  //Listar trabajador
  static String obtenerTrabajadores(int idEmpresa) =>
      "$baseUrl/usuarios/trabajador/obtener_trabajadores.php?id_empresa=$idEmpresa";
  //Cambiar estado del trabajador
  static const String cambiarEstado = "$baseUrl/usuarios/trabajador/cambiar_estado.php";
  //Eliminar trabajador
  static const String eliminarTrabajador = "$baseUrl/usuarios/trabajador/eliminar_trabajador.php";

  //Modulo de insumos
  //Registrar Insumo
  static const String registrarInsumo = "$baseUrl/insumos/registrar.php";
  //Listar Insumo
  static const String listarInsumos = "$baseUrl/insumos/listar.php";
  //Aactualizar Insumo
  static const String editarInsumo = "$baseUrl/insumos/actualizar.php";
    //Buscar Insumo
  static const String buscarInsumo = "$baseUrl/insumos/buscar.php";

}