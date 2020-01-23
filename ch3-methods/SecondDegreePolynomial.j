.class public SecondDegreePolynomial
	
	;calculate ax^2 + bx + c
	;signature evaluate(a, b, c, x)
	.method public static evaluate(DDDD)D
	.limit stack 6
		dload_0
		dload 6
		dload 6 
		dmul
		dmul
		dload_2
		dload 6
		dmul
		dadd
		dload 4
		dadd
		dreturn
	.end method
	
	;calculate ax^2 + bx + c using ((ax+b)x)+c
	;signature evaluate2(a, b, c, x)
	.method public static evaluate2(DDDD)D
		dload_2
		dload 6
		dload_0
		dmul
		dadd
		dload 6
		dmul
		dload 4
		dadd
		dreturn
	.end method		
	
.end class