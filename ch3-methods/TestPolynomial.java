public class TestPolynomial{
	public static void main(String[] args){
		System.out.println("first method:  2*3^2 + 1*3 + 5 = " 
			+ SecondDegreePolynomial.evaluate(2, 1, 5, 3));
		System.out.println("second method: 2*3^2 + 1*3 + 5 = " 
			+ SecondDegreePolynomial.evaluate(2, 1, 5, 3));
	}
}