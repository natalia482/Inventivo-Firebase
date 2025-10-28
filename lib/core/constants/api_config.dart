class ApiConfig {

  static const String baseUrl = "http://192.168.25.16/inventivo_backend/api";
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
=======
  //eliminar Insumo
  static const String eliminarInsumo = "$baseUrl/insumos/eliminar.php";
  //Registrar el uso de insumos
  static const String registrarUsoInsumo = "$baseUrl/insumos/registrar_uso.php";
  //Lista el uso de insumos
  static String listarAbonos(int idEmpresa) =>
    "$baseUrl/insumos/listar_uso.php?id_empresa=$idEmpresa";

>>>>>>> 214d5cfcd22b0afec5d18a6c07c7a8424b60c8ab

  //Modulo de Plantas (CRUD)
  static const String registrarPlantas = "$baseUrl/plantas/agregar.php";
  static const String listarPlantas = "$baseUrl/plantas/listar.php";
  static const String editarPlantas= "$baseUrl/plantas/actualizar.php";
  static const String eliminarPlantas= "$baseUrl/plantas/eliminar.php";

//Modulo de Facturas
static const String registrarFactura = "$baseUrl/facturas/agregar.php";
static const String listarFacturas = "$baseUrl/facturas/listar.php";
static const String eliminarFactura = "$baseUrl/facturas/eliminar.php";
static const String verDetalleFactura = "$baseUrl/facturas/detalle.php";
}