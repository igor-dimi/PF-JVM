public class TestIntegerPolynomial{
	public static void main(String[] args){
		System.out.println("2*3^2 + 1*3 + 5 = " 
			+ SecondDegreeIntegerPolynomial.evaluate(2, 1, 5, 3));
	}
}