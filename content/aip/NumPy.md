AI Programming - SW Lee

# Lab 01: Numpy Basic

This jupyter notebook is taken from Dr. Alex Vakanski's 2022 CS404/504 class at U of Idaho.<br>
You can find the whole notebooks at https://github.com/avakanski/Fall-2022-Python-Programming-for-Data-Science

# Lecture 9 NumPy for Array Operations

- [9.1 Introduction to NumPy](#section1)
- [9.2 NumPy Array Construction and Indexing](#section2)
- [9.3 NumPy Array Math](#section3)
- [9.4 NumPy Broadcasting](#section4)
- [9.5 Random Number Generators](#section5)
- [9.6 Reshaping NumPy Arrays](#section6)
- [9.7 Linear Algebra with NumPy](#section7)
- [9.8 Appendix: Motivation for Using NumPy](#section8)
- [References](#section9)

# 9.1 Introduction to NumPy <a id="section1"/>

NumPy (short for Numerical Python) was created in 2005, and since then, the NumPy library has evolved into an essential library for scientific computing in Python. It has become a building block of many other scientific libraries, such as SciPy, Scikit-learn, Pandas, and others.

NumPy provides a convenient Python interface for working with multi-dimensional array data structures. The NumPy array data structure is also called `ndarray`, which is short for *n*-dimensional array. 

In addition to being mostly implemented in C and using Python as a "glue language," the main reason why NumPy is so efficient for numerical computations is that NumPy arrays use contiguous blocks of memory that can be efficiently cached by the CPU. In contrast, Python lists are arrays of pointers to objects in random locations in memory, which cannot be easily cached and come with a more expensive memory look-up. On the other hand, NumPy arrays have a fixed size and are homogeneous, which means that all elements in an array must have the same type. Homogenous `ndarray` objects have the advantage that NumPy can carry out operations using efficient C code and avoid expensive type checks and other overheads of the Python API. 

### N-dimensional Arrays

NumPy is built around [`ndarrays`](https://docs.scipy.org/doc/numpy/reference/generated/numpy.ndarray.html) objects, which are multi-dimensional array data structures. Intuitively, we can think of a one-dimensional NumPy array as a vector of elements -- you may think of it as a fixed-size Python list where all elements share the same type. Similarly, we can think of a two-dimensional array as a data structure to represent a matrix (or a Python list of lists). NumPy arrays can have up to 32 dimensions. For instance, RGB images have 3 dimensions, corresponding to pixels width and height, and the three color channels. Similarly, an RGB video has 4 dimensions, corresponding to pixels width and height, color channel, and frame number.

In this next example, we will call the `array` function first to create an one-dimensional NumPy array, and afterward, a two-dimensional NumPy array, consisting of two rows and three columns (from a list of lists).

```python
import numpy as np

ary1d = [1., 2., 3.]
np.array(ary1d)
```

    array([1., 2., 3.])

```python
lst = [[1, 2, 3], 
       [4, 5, 6]]

ary2d = np.array(lst)
ary2d

# rows x columns
```

    array([[1, 2, 3],
           [4, 5, 6]])

By default, NumPy infers the type of the array upon construction. Since we passed Python integers to the array, the `ndarray` object `ary2d` should be of type `int32`, which we can confirm by accessing the `dtype` attribute.

```python
ary2d.dtype
```

    dtype('int32')

If we want to construct NumPy arrays of different types, we can pass an argument for the `dtype` parameter of the array using the `astype` method (for example `np.int64` to create 64-bit arrays). For a full list of supported data types, please refer to the official [NumPy documentation](https://docs.scipy.org/doc/numpy/user/basics.types.html). 

```python
int64_ary = ary2d.astype(np.int64)
int64_ary
```

    array([[1, 2, 3],
           [4, 5, 6]], dtype=int64)

```python
float32_ary = ary2d.astype(np.float32)
float32_ary
```

    array([[ 1.,  2.,  3.],
           [ 4.,  5.,  6.]], dtype=float32)

```python
float32_ary.dtype
```

    dtype('float32')

To return the number of elements in an array, we can use the `size` attribute, as shown below.

```python
ary2d.size
```

    6

And the number of dimensions of our array can be obtained via the `ndim` attribute.

```python
ary2d.ndim
```

    2

If we are interested in the number of elements along each array dimension (in the context of NumPy arrays, we may also refer to them as *axes*), we can access the `shape` attribute as shown below.

```python
ary2d.shape
```

    (2, 3)

The `shape` is always a tuple; in the code example above, the two-dimensional `ary2d` object has two *rows* and *three* columns, `(2, 3)`.

The `shape` of a one-dimensional array only contains a single value.

```python
np.array([1., 2., 3.]).shape
```

    (3,)

# 9.2 NumPy Array Construction and Indexing <a id="section2"/>

This section provides several useful functions to construct arrays, e.g., containing only ones or zeros.

```python
np.ones((3, 4), dtype=np.int)
```

    array([[1, 1, 1, 1],
           [1, 1, 1, 1],
           [1, 1, 1, 1]])

```python
np.zeros((3, 3))
```

    array([[ 0.,  0.,  0.],
           [ 0.,  0.,  0.],
           [ 0.,  0.,  0.]])

We can use these functions to create arrays with arbitrary values, e.g., we can create an array containing the values 99 as follows.

```python
np.zeros((3, 3)) + 99
```

    array([[ 99.,  99.,  99.],
           [ 99.,  99.,  99.],
           [ 99.,  99.,  99.]])

Creating arrays of ones or zeros can also be useful as placeholder arrays, in cases where we do not want to use the initial values for computations right away. 

NumPy also has functions to create identity matrices and diagonal matrices as `ndarrays`. 

```python
np.eye(3)
```

    array([[ 1.,  0.,  0.],
           [ 0.,  1.,  0.],
           [ 0.,  0.,  1.]])

```python
np.diag((1, 2, 3))
```

    array([[1, 0, 0],
           [0, 2, 0],
           [0, 0, 3]])

Two other very useful functions for creating sequences of numbers within a specified range are `arange` and `linspace`. NumPy's `arange` function follows the same syntax as Python's `range` function. If two arguments are provided, the first argument represents the start value and the second argument defines the stop value of a half-open interval.

```python
np.arange(4, 10)
```

    array([4, 5, 6, 7, 8, 9])

If we only provide a single argument, the default start value of 0 is assumed.

```python
np.arange(5)
```

    array([0, 1, 2, 3, 4])

Similar to Python's `range`, a third argument can be provided to define the *step* (the default step size is 1). For example, we can obtain an array of all values between 1 and 11 with 0.1 step as follows.

```python
ary3 = np.arange(1., 11., 0.1)
ary3
```

    array([  1. ,   1.1,   1.2,   1.3,   1.4,   1.5,   1.6,   1.7,   1.8,
             1.9,   2. ,   2.1,   2.2,   2.3,   2.4,   2.5,   2.6,   2.7,
             2.8,   2.9,   3. ,   3.1,   3.2,   3.3,   3.4,   3.5,   3.6,
             3.7,   3.8,   3.9,   4. ,   4.1,   4.2,   4.3,   4.4,   4.5,
             4.6,   4.7,   4.8,   4.9,   5. ,   5.1,   5.2,   5.3,   5.4,
             5.5,   5.6,   5.7,   5.8,   5.9,   6. ,   6.1,   6.2,   6.3,
             6.4,   6.5,   6.6,   6.7,   6.8,   6.9,   7. ,   7.1,   7.2,
             7.3,   7.4,   7.5,   7.6,   7.7,   7.8,   7.9,   8. ,   8.1,
             8.2,   8.3,   8.4,   8.5,   8.6,   8.7,   8.8,   8.9,   9. ,
             9.1,   9.2,   9.3,   9.4,   9.5,   9.6,   9.7,   9.8,   9.9,
            10. ,  10.1,  10.2,  10.3,  10.4,  10.5,  10.6,  10.7,  10.8,  10.9])

Note the shape of this array.

```python
np.shape(ary3)
```

    (100,)

The `linspace` function is especially useful if we want to create a number of evenly spaced values in a specified interval.

```python
np.linspace(6., 25., num=5)
```

    array([  6.  ,  10.75,  15.5 ,  20.25,  25.  ])

### Array Indexing

Simple NumPy indexing and slicing work similar to Python lists, as in the following examples.

```python
ary = np.array([1, 2, 3, 4])
ary[2]
```

    3

Also, the same Python semantics apply to slicing operations. The following example shows how to fetch the first three elements in `ary`.

```python
ary[0:3] 
```

    array([1, 2, 3])

If we work with arrays that have more than one dimension or axis, we separate our indexing or slicing operations by commas as shown in the following examples.

```python
ary = np.array([[1, 2, 3],
                [4, 5, 6]])

ary[0, -2] # first row, second from last element
```

    2

```python
ary[-1, -1] # lower right
```

    6

```python
ary[1, 1] # first row, second column
```

    5

```python
ary[:, 0] # entire first column
```

    array([1, 4])

```python
ary[:, :2] # first two columns
```

    array([[1, 2],
           [4, 5]])

# 9.3 NumPy Array Math <a id="section3"/>

One of the core features of NumPy that makes working with `ndarray` so efficient and convenient is ***vectorization***. NumPy provides vectorized functions for performing element-wise operations implicitly via so-called *ufuncs* which is short for universal functions.

There are more than 60 ufuncs available in NumPy; ufuncs are implemented in compiled C code and very fast and efficient compared to Python. 

To provide an example of a simple ufunc for element-wise addition, consider the following example, where we add a scalar 1 to each element in a nested Python list.

```python
lst = [[1, 2, 3], 
       [4, 5, 6]] # 2d array

for row_idx, row_val in enumerate(lst):
    for col_idx, col_val in enumerate(row_val):
        lst[row_idx][col_idx] += 1
lst
```

    [[2, 3, 4], [5, 6, 7]]

We can accomplish the same using NumPy's ufunc for element-wise scalar addition as shown below.

```python
ary = np.array([[1, 2, 3], [4, 5, 6]])
ary = np.add(ary, 1) 
ary
```

    array([[2, 3, 4],
           [5, 6, 7]])

```python
 
```

For basic arithmetic operations we can use `add`, `subtract`, `divide`, `multiply`, `power`, and `exp` (exponential). However, NumPy uses operator overloading so that we can use mathematical operators (`+`, `-`, `/`, `*`, and `**`) directly.

```python
np.add(ary, 1)
```

    array([[3, 4, 5],
           [6, 7, 8]])

```python
ary + 1
```

    array([[3, 4, 5],
           [6, 7, 8]])

```python
np.power(ary, 2)
```

    array([[ 4,  9, 16],
           [25, 36, 49]], dtype=int32)

```python
ary**2
```

    array([[ 4,  9, 16],
           [25, 36, 49]], dtype=int32)

NumPy also has implementations for other math operations, such as `sqrt` (square root), `log` (natural logarithm), and `log10` (base-10 logarithm).

```python
np.sqrt(ary)
```

    array([[ 1.41421356,  1.73205081,  2.        ],
           [ 2.23606798,  2.44948974,  2.64575131]])

Often, we want to compute the sum or product of array elements along a given axis. For this purpose, we can use the `reduce` operation. By default, `reduce` applies an operation along the first axis (`axis=0`). In the case of a two-dimensional array, we can think of the first axis as the rows of a matrix. Thus, adding up elements along rows yields the column sums of that matrix as shown below.

```python
ary = np.array([[1, 2, 3], 
                [4, 5, 6]]) # rolling over the 1st axis, axis 0

np.add.reduce(ary, axis=0)
```

    array([5, 7, 9])

To compute the row sums of the array above, we can specify `axis=1`.

```python
np.add.reduce(ary, axis=1) # row sums
```

    array([ 6, 15])

NumPy also provides functions for specific operations such as `product` and `sum`. For example, `sum(axis=0)` is equivalent to `add.reduce`.

```python
ary.sum(axis=0) # column sums
```

    array([5, 7, 9])

```python
ary.sum(axis=1) # row sums
```

    array([ 6, 15])

Note also that `product` and `sum` both compute the product or sum of the entire array if we do not specify an axis.

```python
ary.sum()
```

    21

Other useful ufuncs are:
    
- `np.mean` (computes arithmetic mean or average)
- `np.std` (computes the standard deviation)
- `np.var` (computes variance)
- `np.sort` (sorts an array)
- `np.argsort` (returns indices that would sort an array)
- `np.min` (returns the minimum value of an array)
- `np.max` (returns the maximum value of an array)
- `np.argmin` (returns the index of the minimum value)
- `np.argmax` (returns the index of the maximum value)
- `np.array_equal` (checks if two arrays have the same shape and elements)

# 9.4 NumPy Broadcasting <a id="section4"/>

***Broadcasting*** allows to perform vectorized operations between two arrays even if their dimensions do not match. 

```python
ary1 = np.array([1, 2, 3])
ary1 + 1
```

    array([2, 3, 4])

```python
# this is equivalent to:
ary1 + np.array([1, 1, 1])
```

    array([2, 3, 4])

For example, we can add a one-dimensional to a two-dimensional array, where NumPy creates an implicit multidimensional grid from the one-dimensional array `ary1`.

```python
ary2 = np.array([[4, 5, 6], 
                 [7, 8, 9]])

ary2 + ary1
```

    array([[ 5,  7,  9],
           [ 8, 10, 12]])

Using broadcasting in Python requires compatibility between the sizes of the arrays. For instance, if we try to add two arrays of sizes (3,3) and (2,2), Python will return an error.

```python
np.ones((3,3)) + np.ones((2,2))
```

    ---------------------------------------------------------------------------

    ValueError                                Traceback (most recent call last)

    Cell In[2], line 1
    ----> 1 np.ones((3,3)) + np.ones((2,2))
    
    ValueError: operands could not be broadcast together with shapes (3,3) (2,2) 

### Advanced Indexing -- Memory Views and Copies

In the previous sections, we used basic indexing and slicing routines. It is important to note that basic integer-based indexing and slicing create so-called *views* of NumPy arrays in the memory. Working with views can be highly desirable since it avoids making unnecessary copies of arrays to save memory resources. To illustrate the concept of memory views, let's look at a simple example where we access the first row in an array, assign it to a variable, and modify that variable.

```python
ary = np.array([[1, 2, 3],
                [4, 5, 6]])

first_row = ary[0, :]
```

```python
first_row
```

    array([1, 2, 3])

```python
first_row += 99
```

```python
first_row
```

    array([100, 101, 102])

As expected, `first_row` was modified, now containing the original values in the first row incremented by 99.

Note, however, that the original array was modified as well. The reason for this is that `ary[0, :]` created a view of the first row in `ary`, and its elements were then incremented by 99. 

```python
ary
```

    array([[100, 101, 102],
           [  4,   5,   6]])

The same concept applies to slicing operations.

```python
ary = np.array([[1, 2, 3],
                [4, 5, 6]])

last_col = ary[:, 2]
last_col += 99
ary
```

    array([[  1,   2, 102],
           [  4,   5, 105]])

Therefore, it is important to be aware that indexing and slicing create views, which can speed up our code by avoiding to create unnecessary copies in memory. However, in certain scenarios we want to create a copy of an array; we can do this via the `copy` method as shown below.

```python
ary = np.array([[1, 2, 3],
                [4, 5, 6]])

first_row = ary[0].copy()
first_row += 99
```

```python
first_row
```

    array([100, 101, 102])

```python
ary
```

    array([[1, 2, 3],
           [4, 5, 6]])

### Fancy Indexing

In addition to basic single-integer indexing and slicing operations, NumPy supports advanced indexing routines called *fancy indexing*. Via fancy indexing, we can use tuple or list objects of non-contiguous integer indices to return desired array elements. Since fancy indexing can be performed with non-contiguous sequences, it cannot return a view -- a contiguous slice from memory. Thus, fancy indexing always returns a copy of an array: it is important to keep that in mind. The following code snippets show some fancy indexing examples.

```python
ary = np.array([[1, 2, 3],
                [4, 5, 6]])

ary[:, [0, 2]] # first and and last column
```

    array([[1, 3],
           [4, 6]])

```python
this_is_a_copy = ary[:, [0, 2]]
this_is_a_copy += 99
```

Note that the values in `this_is_a_copy` were incremented as expected.

```python
this_is_a_copy
```

    array([[100, 102],
           [103, 105]])

However, the contents of the original array remain unaffected.

```python
ary
```

    array([[1, 2, 3],
           [4, 5, 6]])

### Boolean Masks for Indexing

We can also use Boolean masks for indexing, that is, arrays of `True` and `False` values. Consider the following example, where we return all values in the array that are greater than 3.

```python
ary = np.array([[1, 2, 3],
                [4, 5, 6]])

greater3_mask = ary > 3
greater3_mask
```

    array([[False, False, False],
           [ True,  True,  True]], dtype=bool)

Using these masks, we can select elements given our desired criteria.

```python
ary[greater3_mask]
```

    array([4, 5, 6])

Or, we can also write this as follows.

```python
ary[ary>3]
```

    array([4, 5, 6])

We can also chain different selection criteria using the logical *and* operator `&` or the logical *or* operator `|`. The example below demonstrates how we can select array elements that are greater than 3 and divisible by 2.

```python
(ary > 3) & (ary % 2 == 0)
```

    array([[False, False, False],
           [ True, False,  True]], dtype=bool)

Similar to the previous example, we can use this boolean array as a mask for selecting the respective elements from the array.

```python
ary[(ary > 3) & (ary % 2 == 0)]
```

    array([4, 6])

And, for example, to negate a condition, we can use the `~` operator:

```python
ary[~((ary > 3) | (ary < 2))]
```

    array([2, 3])

A related, useful function to assign values to specific elements in an array is the `np.where` function. In the example below, we assign a 1 to all values in the array that are greater than 2, and 0 otherwise.

```python
ary = np.array([1, 2, 3, 4, 5])

np.where(ary > 2, 1, 0)
```

    array([0, 0, 1, 1, 1])

# 9.5 Random Number Generators <a id="section5"/>

In machine learning and data science, we often need to generate arrays of random numbers, such as the initial values of the model parameters. NumPy has a `random` subpackage to create random numbers and samples from a variety of distributions. 

Let's start with drawing a random sample of three numbers in the range [0,1] from a uniform distribution via `random.rand`.

```python
np.random.rand(3)
```

    array([ 0.6852787 ,  0.40035022,  0.53455291])

If we make another draw, we will obtain a different random sample. 

```python
np.random.rand(3)
```

    array([ 0.81577185,  0.56947541,  0.18939207])

Numpy also allows to use a fixed *random seed* for the  random number generator, and in that case, the random sample will be same at each draw. 

```python
np.random.seed(123)

np.random.rand(3)
```

    array([ 0.69646919,  0.28613933,  0.22685145])

```python
np.random.seed(123)

np.random.rand(3)
```

    array([ 0.69646919,  0.28613933,  0.22685145])

And, of course, if we change the random seed value, the generated random numbers will be also different.

```python
np.random.seed(43)

np.random.rand(3)
```

    array([ 0.11505457,  0.60906654,  0.13339096])

Using a random seed is highly recommended in practical applications and in research projects, since it ensures that our results are reproducible, since using the same seed will create the same random numbers. 

We can also create  multi-dimensional arrays of random numbers, if needed.

```python
np.random.rand(5,5)
```

    array([[ 0.24058962,  0.32713906,  0.85913749,  0.66609021,  0.54116221],
           [ 0.02901382,  0.7337483 ,  0.39495002,  0.80204712,  0.25442113],
           [ 0.05688494,  0.86664864,  0.221029  ,  0.40498945,  0.31609647],
           [ 0.0766627 ,  0.84322469,  0.84893915,  0.97146509,  0.38537691],
           [ 0.95448813,  0.44575836,  0.66972465,  0.08250005,  0.89709858]])

And, we can draw random numbers from other distributions. For instance, `random.randn` returns random numbers from a normal, i.e., Gaussian, distribution, with mean 0, and variance 1. 

```python
np.random.randn(4)
```

    array([-1.04683899, -0.88961759,  0.01404054, -0.16082969])

Or, for instance if we needed to generate 6 random values from a normal distribution with mean -3 and standard deviation 10, we can write as follows.

```python
-3 + 10*np.random.randn(6)
```

    array([ 19.30359649,  -6.99115719,  -2.45555437,   5.84181815,
            -4.07980561,   2.55606984])

Also, it can be useful to create separate `RandomState` objects for various parts of our code, so that we can test methods in a reproducible manner. The example below shows how we can use a `RandomState` object to create the same results that we obtained via `np.random.rand` in the previous code.

```python
rng2 = np.random.RandomState(seed=123)
rng2.rand(3)
```

    array([ 0.69646919,  0.28613933,  0.22685145])

In the above code, `np.random.RandomState()` constructed a random number generator that we named `rng2`. When we call `rng2` to draw random numbers, it uses the specified seed (seed=123) to create random numbers in a controlled way. Note however that the seed 123 will be applied only to the `rng2` object, and it does not have effect on other freestanding functions in our code that use `np.random`. If we would like to apply the random seed 123 to all other  `np.random` functions in our code, we will need to explicitly request this with `np.random.seed(123)`.

# 9.6 Reshaping NumPy Arrays <a id="section6"/>

In practice, we often run into situations where existing arrays do not have the *right* shape to perform certain computations. As you might remember from the beginning of this article, the size of NumPy arrays is fixed. Fortunately, this does not mean that we have to create new arrays and copy values from the old array to the new one if we want arrays of different shapes. That is, the size is fixed, but the shape is not. NumPy provides a `reshape` method that allows to obtain a view of an array with a different shape. 

For example, we can reshape a one-dimensional array into a two-dimensional one using `reshape` as follows.

```python
ary1d = np.array([1, 2, 3, 4, 5, 6])
ary2d_view = ary1d.reshape(2, 3)
ary2d_view
```

    array([[1, 2, 3],
           [4, 5, 6]])

```python
np.may_share_memory(ary2d_view, ary1d)
```

    True

```python
ary1d
```

    array([1, 2, 3, 4, 5, 6])

```python
ary2d_view
```

    array([[1, 2, 3],
           [4, 5, 6]])

--> 넘파이는 데이터와 메타데이터로 나누어 정보를 저장한다. 
메모리를 공유한다는 것은 데이터 메모리를 공유한다는 것으로, 이 사이즈는 정해져있다. 
하지만 메타데이터는 배열마다 다를 수 있다.
이것은 배열마다 같은 데이터를 가지되 다른 shape을 가질 수 있다는 것이다.

The `True` value returned from `np.may_share_memory` indicates that the reshape operation returns a memory view, not a copy.

When using reshape, we need to make sure that the reshaped array has the same number of elements as the original one. Otherwise, we will obtain an error message.

```python
ary2d_view1 = ary1d.reshape(3, 4)
```

    ---------------------------------------------------------------------------

    ValueError                                Traceback (most recent call last)

    <ipython-input-74-a89f26e6becd> in <module>
    ----> 1 ary2d_view1 = ary1d.reshape(3, 4)
    
    ValueError: cannot reshape array of size 6 into shape (3,4)

However, we do not need to specify the number of elements in each axis. NumPy can figure out how many elements to put along an axis if only one axis is unspecified, by using the placeholder `-1`.

```python
ary1d.reshape(-1, 2)
```

    array([[1, 2],
           [3, 4],
           [5, 6]])

--> -1이 있는 자리는 알아서 값을 넣으라는거다.
그러니까 (-1, 2) 는 열 2개 만들어서 행은 알아서 맞추라는거. 
당연히 나누어떨어지는 숫자로 나머지 숫자를 채워둬야한다. 

We can also use `reshape` to flatten an array.

```python
ary = np.array([[[1, 2, 3],
                 [4, 5, 6]]])

ary.reshape(-1)
```

    array([1, 2, 3, 4, 5, 6])

Other methods for flattening arrays exist, namely `flatten`, which creates a copy of the array, and `ravel`, which creates a memory view.

```python
ary.flatten()
```

    array([1, 2, 3, 4, 5, 6])

```python
ary.ravel()
```

    array([1, 2, 3, 4, 5, 6])

Sometimes, we are interested in merging different arrays. Unfortunately, there is no efficient way to do this without creating a new array, since NumPy arrays have a fixed size. While combining arrays should be avoided if possible for reasons of computational efficiency, it is sometimes necessary. To combine two or more array objects, we can use NumPy's `concatenate` function as shown in the following examples.

```python
ary = np.array([[1, 2, 3]])

# stack along the first axis (here: rows)
np.concatenate((ary, ary), axis=0)
```

    array([[1, 2, 3],
           [1, 2, 3]])

```python
# stack along the second axis (here: columns)
np.concatenate((ary, ary), axis=1)
```

    array([[1, 2, 3, 1, 2, 3]])

Two related functions are `vstack` and `hstack` that stand for vertically or horizontally stacking arrays, respectively. 

```python
np.vstack((ary, ary))
```

    array([[1, 2, 3],
           [1, 2, 3]])

```python
np.hstack((ary, ary))
```

    array([[1, 2, 3, 1, 2, 3]])

# 9.7 Linear Algebra with NumPy <a id="section7"/>

We can think of one-dimensional NumPy arrays as data structures that represent row vectors.

```python
row_vector = np.array([1, 2, 3])
row_vector
```

    array([1, 2, 3])

```python
row_vector.shape
```

    (3,)

Similarly, we can use two-dimensional arrays to create column vectors.

```python
column_vector = np.array([1, 2, 3]).reshape(-1, 1)
column_vector
```

    array([[1],
           [2],
           [3]])

```python
column_vector.shape
```

    (3, 1)

Instead of reshaping a one-dimensional array into a two-dimensional one, we can simply add a new axis as shown below.

```python
row_vector[:, np.newaxis]
```

    array([[1],
           [2],
           [3]])

--> 이건 np.newaxis 자리에 새 축을 만드는 거다. 
reshape이랑 비슷한데, reshape은 만들어질 최종 형태를 쓰고 newaxis는 어디에 축을 추가할지 쓴다.
예제에서는 row_vector는 원래 행도 열도 아닌 원소 3개였다. (3, )
여기서 :로 기존의 원소 3개를 유지하고, newaxis로 열을 추가한 것이다. 
그러면 (3, 1) 의 열벡터가 된다.



To perform matrix multiplication between matrices, we know that number of columns of the left matrix must match the number of rows of the matrix to the right. In NumPy, we can perform matrix multiplication via the `matmul` function.

```python
matrix = np.array([[1, 2, 3], 
                   [4, 5, 6]])
```

```python
np.matmul(matrix, column_vector)
```

    array([[14],
           [32]])

However, if we are working with matrices and vectors, NumPy can be quite forgiving if the dimensions of matrices and one-dimensional arrays do not match exactly -- thanks to broadcasting. The following example yields the same result as the matrix-column vector multiplication, except that it returns a one-dimensional array instead of a two-dimensional one.

```python
np.matmul(matrix, row_vector)
```

    array([14, 32])

Similarly, we can compute the dot-product between two vectors (here: the vector norm).

```python
np.matmul(row_vector, row_vector)
```

    14

NumPy has a special `dot` function that calculates the dot-product for one-dimensional arrays, and otherwise behaves similar to `matmul` on multi-dimensional arrays.

```python
np.dot(matrix, row_vector)
```

    array([14, 32])

Note that an even more convenient way for executing `np.dot` is using the `@` symbol with NumPy arrays.

```python
matrix @ row_vector
```

    array([14, 32])

NumPy also has a handy `transpose` method to transpose matrices (two-dimensional arrays).

```python
matrix = np.array([[1, 2, 3], 
                   [4, 5, 6]])

matrix.transpose()
```

    array([[1, 4],
           [2, 5],
           [3, 6]])

There is also a shorthand for `transpose` simply as `T`.

```python
matrix.T
```

    array([[1, 4],
           [2, 5],
           [3, 6]])

While this section demonstrates some of the basic linear algebra operations carried out on NumPy arrays that we use in practice, you can find additional functions in the documentation of NumPy's submodule for linear algebra: [`numpy.linalg`](https://docs.scipy.org/doc/numpy/reference/routines.linalg.html). If you want to perform a particular linear algebra routine that is not implemented in NumPy, it is also worth consulting the [`scipy.linalg` documentation](https://docs.scipy.org/doc/scipy/reference/linalg.html) -- SciPy is a library for scientific computing built on top of NumPy.

One last note is that there is also a special [`matrix`](https://docs.scipy.org/doc/numpy/reference/generated/numpy.matrix.html) type in NumPy. NumPy `matrix` objects are analogous to NumPy arrays but are restricted to two dimensions. Also, matrices define certain operations differently than arrays; for instance, the `*` operator performs matrix multiplication instead of element-wise multiplication. However, NumPy `matrix` is less popular in the science community compared to the more general array data structure. 

# 9.8 Appendix (not required for quizzes and assignments) <a id="section8"/>

# Motivation for Using NumPy: It is Fast!

Let's compare computing a vector dot product in Python (using lists) and compare it with  NumPy's dot-product function. Mathematically, the dot product between two vectors $\mathbf{x}$ and $\mathbf{w}$ can be written as follows:

$$
z = \sum_i x_i w_i = x_1 \times w_1 + x_2 \times w_2 + ... + x_n \times w_n = \mathbf{x}^\top \mathbf{w} 
$$

First, the Python implementation using a for-loop.

```python
def python_forloop_list_approach(x, w):
    z = 0.
    for i in range(len(x)):
        z += x[i] * w[i]
    return z


a = [1., 2., 3.]
b = [4., 5., 6.]

print(python_forloop_list_approach(a, b))
```

    32.0
    
Let us compute the runtime for two larger (1000-element) vectors using IPython's `%timeit` magic function.

```python
large_a = list(range(1000))
large_b = list(range(1000))


%timeit python_forloop_list_approach(large_a, large_b)
```

    152 µs ± 18.6 µs per loop (mean ± std. dev. of 7 runs, 10000 loops each)
    
Next, we use the `dot` function/method implemented in NumPy to compute the dot product between two vectors and run `%timeit` afterwards.

```python
def numpy_dotproduct_approach(x, w):
    # same as np.dot(x, w)
    # and same as x @ w
    return x.dot(w)
    

a = np.array([1., 2., 3.])
b = np.array([4., 5., 6.])

print(numpy_dotproduct_approach(a, b))
```

    32.0
    
```python
large_a = np.arange(1000)
large_b = np.arange(1000)

%timeit numpy_dotproduct_approach(large_a, large_b)
```

    1.59 µs ± 23 ns per loop (mean ± std. dev. of 7 runs, 1000000 loops each)
    
As we can see, replacing the for-loop with NumPy's dot function makes the computation of the vector dot product approximately 100 times faster.

# References <a id="section9"/>

1. Scientific Computing in Python: Introduction to NumPy and Matplotlib, by Sebastian Raschka, available at: [https://sebastianraschka.com/blog/2020/numpy-intro.html](https://sebastianraschka.com/blog/2020/numpy-intro.html).
