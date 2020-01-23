.class public  SecondDegreeIntegerPolynomial
	
	;compute the integer polynomial a*x^2 + b*x + c
	;method signature evaluate(a, b, c, x)
	.method public static evaluate(IIII)I
	.limit stack 3
		iload_0
		iload_3
		iload_3
		imul
		imul
		iload_1
		iload_3
		imul
		iadd
		iload_2
		iadd
		ireturn
	.end method
	
.end class