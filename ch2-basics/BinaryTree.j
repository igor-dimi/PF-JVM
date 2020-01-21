.class BinaryTree

	.field private leftLink BinaryTree
	.field private rightLink BinaryTree
	.field private data Ljava/lang/Object;
	
	.method public computeSum(FF)F
		.limit locals 3
		.limit stack 2
		fload_1
		fload_2
		fadd
		freturn
	.end method
	
.end class 