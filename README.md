# gpuHAVOK (outdated!)
This is a testbed for system identification and forecasting of dynamical systems using the Hankel Alternative View of Koopman (HAVOK) algorithm. This code is based on work by Brunton & Kutz (2022) ["Data-Driven Science and Engineering", Cambridge University Press, URL: https://www.cambridge.org/highereducation/product/9781009089517/book], and my aim is to improve the efficiency of the algorithm through GPU/CPU optimization. The code is structured as follows:

1. **simulateModel.m**

Generates some data from a linear or nonlinear system (which can be provided) and finds a Koopman-based linear representation of the system in delay coordinates using the Hankel Alternative View of Koopman (HAVOK) algorithm. This code requires the specification of the following parameters:

- x,t,x0 - Single-variable data, x, from a system at times t, with initial condition x0.
- stackmax - number of time(delay)-shifted copies of the data x, which represents the memory of the HAVOK model. Similar to an Auto-Regressive model, A longer memory allows for longer dependencies, but increases the complexity of the model.
- rmax - the maximum rank of the HAVOK model, defined as the maximum number of singular values to retain when performing Singular Value Decomposition (SVD). A low rank model retains only the lower order statistics (moments) of the system, whereas a higher rank model also captures     higher order moments and more detail.

---

2. **sysidHAVOK.m**

Returns a function dvdt representing a Koopman-based linearization of the data x from a nonlinear system. The algorithm essentially decomposes a nonlinear system x into a set of linearized systems of equations dv/dt = A v_[1:r-1](t) plus a nonlinear intermittent forcing term B v_r(t): dv/dt = A v_[1:r-1](t) + B v_r(t)
=======
- rmax - the maximum rank of the HAVOK model, defined as the maximum number of singular values to retain when performing Singular Value Decomposition (SVD). A low rank model retains only the lower order statistics (moments) of the system, whereas a higher rank model also captures higher order moments and more detail.
=======
  - x,t,x0 - Single-variable data, x, from a system at times t, with initial condition x0.
  - stackmax - number of time(delay)-shifted copies of the data x, which represents the memory of the HAVOK model. Similar to an Auto-Regressive   
    model, A longer memory allows for longer dependencies, but increases the complexity of the model.
  - rmax - the maximum rank of the HAVOK model, defined as the maximum number of singular values to retain when performing Singular Value       
    Decomposition (SVD). A low rank model retains only the lower order statistics (moments) of the system, whereas a higher rank model also captures     higher order moments and more detail.
>>>>>>> e83d2d9 (Update README.md)

2. **sysidHAVOK.m** returns a function dvdt representing a Koopman-based linearization of the data x from a nonlinear system. The algorithm essentially decomposes a nonlinear system x into a set of linearized systems of equations dv/dt = A v_[1:r-1](t) plus a nonlinear intermittent forcing term B v_r(t): dv/dt = A v_[1:r-1](t) + B v_r(t)
>>>>>>> 615075a (Update README.md)
=======
---

1. **simulateModel.m**

Generates some data from a linear or nonlinear system (which can be provided) and finds a Koopman-based linear representation of the system in delay coordinates using the Hankel Alternative View of Koopman (HAVOK) algorithm. This code requires the specification of the following parameters:
>>>>>>> 00690ed (Update README.md)

- x,t,x0 - Single-variable data, x, from a system at times t, with initial condition x0.
- stackmax - number of time(delay)-shifted copies of the data x, which represents the memory of the HAVOK model. Similar to an Auto-Regressive model, A longer memory allows for longer dependencies, but increases the complexity of the model.
- rmax - the maximum rank of the HAVOK model, defined as the maximum number of singular values to retain when performing Singular Value Decomposition (SVD). A low rank model retains only the lower order statistics (moments) of the system, whereas a higher rank model also captures     higher order moments and more detail.

---
<<<<<<< HEAD

3. **derivativeCentralDiff4.m**

Computes the discrete derivative of x(t) using a 4th order central difference scheme.

---

5. **generateLinear.m** and **generateLorenz.m**/**lorenzSystem.m**

Generates some linear and nonlinear data, respectively, as default input data for simulateModel.m.

---

6. **impulseHAVOK.m**

Produces and visualizes an impulse response of the system: dxdt = Ax + Bu with measurements y = Cx + Du, where u is a control variable and C and D defines the availability of x and u measurements.
=======
=======
3. **derivativeCentralDiff4.m** computes the discrete derivative of x(t) using a 4th order central difference scheme.
=======
>>>>>>> 00690ed (Update README.md)

2. **sysidHAVOK.m**

Returns a function dvdt representing a Koopman-based linearization of the data x from a nonlinear system. The algorithm essentially decomposes a nonlinear system x into a set of linearized systems of equations dv/dt = A v_[1:r-1](t) plus a nonlinear intermittent forcing term B v_r(t): dv/dt = A v_[1:r-1](t) + B v_r(t)

- The input data x(t) is a vector time series or sequence of numbers generated by a nonlinear system.
- The variable v(t) is a vector representing each scalar value of x(t) in delay coordinates. v_[1:r-1](t) are the first r-1 elements of the vector v(t), whereas v_r(t) represents the r:th element of v(t), where r is an optimal truncation based on the Singular Value Decomposition (SVD)
- A and B are matrices specifying the coupling between the delay-variables in v(t).

---

3. **derivativeCentralDiff4.m**

Computes the discrete derivative of x(t) using a 4th order central difference scheme.

---

5. **generateLinear.m** and **generateLorenz.m**/**lorenzSystem.m**

Generates some linear and nonlinear data, respectively, as default input data for simulateModel.m.

---

6. **impulseHAVOK.m**

Produces and visualizes an impulse response of the system: dxdt = Ax + Bu with measurements y = Cx + Du, where u is a control variable and C and D defines the availability of x and u measurements.
