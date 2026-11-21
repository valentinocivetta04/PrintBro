import Testing
@testable import PrintBroCore

@Test(arguments: [
    ("1-3,5,8-10", "1-3,5,8-10"),
    (" 1 - 3 , 5 ", "1-3,5"),
    ("7", "7"),
    ("2-2", "2-2"),
])
func rangoValidoSeNormaliza(entrada: String, esperado: String) throws {
    #expect(try RangoPaginas.validar(entrada, total: 10) == esperado)
}

@Test(arguments: ["", "0", "3-1", "1,,2", "1-", "-3", "a", "1-2-3", "+3", "1;2", "99999999999999999999"])
func rangoInvalidoDaErrorSinCrashear(entrada: String) {
    #expect(throws: PrintBroError.self) { try RangoPaginas.validar(entrada) }
}

@Test func rangoQueSePasaDelTotal() {
    #expect(throws: PrintBroError.rangoInvalido("El documento tiene 4 páginas y «3-6» se pasa.")) {
        try RangoPaginas.validar("1,3-6", total: 4)
    }
}

@Test func sinTotalNoAcota() throws {
    #expect(try RangoPaginas.validar("50-60") == "50-60")
}
