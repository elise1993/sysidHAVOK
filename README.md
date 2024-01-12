This is a testbed for system identification and forecasting of dynamical systems using the Hankel Alternative View of Koopman (HAVOK) algorithm and Sparse Identification of Nonlinear Dynamics (SINDy). This code is based on the work by Brunton & Kutz (2022) and Yang et. al. (2022).

---

# Background

Any nonlinear dynamical system of the form $\frac{d\mathbf{x}}{dt} = f(\mathbf{x}(t))$ may be represented by an infinite-dimensional linear system, defined by a so-called Koopman-operator (Mezić 2005). Finding an asymptotically large system like this is an ill-posed problem, which has led to the development of methods that attempt to approximate the Koopman operator. One such method is the Dynamic Mode Decomposition (DMD) and its extensions, which have shown great promise at representing nonlinear and chaotic systems. DMD attempts to find a best-fit linear model between the current state $\mathbf{x}(t_k)$ at time $t_k$ and the state at the next time step using regression (1), so that:

$$ \mathbf{x}(t_{k+1}) = \mathbf{A} \mathbf{x}(t_k) \tag{1}$$

While the standard DMD (1) is quite limited in representing nonlinear systems, extensions to the algorithm, such as extended DMD, allow for greater representation. Here, we focus on HAVOK, or Hankel DMD, which is one of the more recent developments. First, HAVOK organizes the sequential timeseries data $``\mathbf{x}(t_k)=\{x(t_k)\}_1^p``$ into a Hankel matrix $\mathbf{H}$ (a matrix of $q$ delayed copies of $\mathbf{x}$) (2), and then applies Singular Value Decomposition (SVD) to this Hankel matrix (3), so that:

```math
\mathbf{H} = \begin{bmatrix} x(t_1) & x(t_2) & \cdots & x(t_p) \\  x(t_2) & x(t_3) & \cdots & x(t_{p+1}) \\  x(t_3) & x(t_4) & \ddots & \vdots \\  x(t_q) & x(t_{q+1}) & \cdots & x(t_{p+q}) \end{bmatrix} \tag{2}
```
⠀
```math
\mathbf{H} = \mathbf{U\Sigma V}^T \tag{3}
```

$U\Sigma$ represents a new coordinate system (delay coordinates) for the system state. Often times, not all of $\mathbf{U\Sigma}$ is required to accurately represent the dynamics, and so these matrices are truncated into the first $r\times r$ block (see Gavish & Donoho, 2014). These delay coordinates turn out to be highly useful for representing systems with long-term memory effects, which are prevalent in many dynamical systems. The variables in these coordinates, or delay variables, are denoted by $`\mathbf{v}=\{ v_i \}_1^{r-1}`$. In (3), $\mathbf{V}$ is a matrix of these delay variables that correspond to the true $\mathbf{x}$, and may be used to train a regression model similar to DMD in these new coordinates (4):

```math
\frac{d\mathbf{V}}{dt} = \mathbf{\Xi} \mathbf{V} \tag{4}
```

where $\frac{d\mathbf{V}}{dt}$ can be either measured or estimated from $\mathbf{V}$. When this regression model is fitted, the last ($r^{\text{th}}$) row of $\mathbf{\Xi}$ is poorly fitted, as this row corresponds to a nonlinear intermittent forcing, whereas the first $(r-1)\times(r-1)$ block of $\mathbf{\Xi}$ represents linear dynamics. As such, HAVOK effectively decomposes a nonlinear system into a intermittently forced linear system of the form:

$$ \frac{d\mathbf{v}}{dt} = \mathbf{A}\mathbf{v} + \mathbf{B}v_r \tag{5}$$

where $\mathbf{A}$ is the first $(r-1)\times(r-1)$ block of $\mathbf{\Xi}$ and $\mathbf{B}$ is the last $r^{\text{th}}$ column. The term $\mathbf{Av}$ provides a good linear approximation of the nonlinear system, which can accurately model linear attractor dynamics on its own, whereas $\mathbf{B} v_r$ is the intermittent forcing term (see Files/main.m). The less we truncate the model (the larger we make $r$ and consequently $\mathbf{A}$), the more accurately the linear model can represent the nonlinear dynamics as well. Two problems emerge here, (a) larger models require more data, and so we cannot just model everything with $\mathbf{A}\mathbf{v}$. (b) Eq (5) is not a closed-form model since the last delay variable $v_r$ is always poorly fitted during the regression procedure for a nonlinear system. If $v_r$ is known, Eq (5) can accurately represent a nonlinear system, even when the model is highly truncated (built using a smaller data set). As such, Yang et. al. (2022) suggested training a Machine Learning (ML) model on $v_r$, and use it as a forcing term for the HAVOK model. This HAVOK-ML procedure has shown high promise in modelling nonlinear systems as is demonstrated here.

---

# Files

**main.m**

This is the main code, which takes some data, interpolates it, partitions it into training/validation/testing sets, and finds a Koopman-based linear representation of the system in delay coordinates using HAVOK analysis and SINDy. It then trains a Machine Learning (ML) method on the intermittent forcing term of HAVOK and uses this forcing model to produce a forecast over the validation period. This code requires the specification of the following parameters:

a) x,t,x0 - Single-variable data, x, from a nonlinear chaotic system sampled at times t, with initial condition x0. Example data are generated from the following systems:

- Lorenz
- Rossler
- VanderPol
- Duffing
- DoublePendulum
- MackeyGlass
- MagneticFieldReversal (Molina-Cardín et. al., 2021)

![image](https://github.com/elise1993/sysidHAVOK/assets/100414021/5775e9f3-4e33-423d-9901-93218edeea81)

b) stackmax - number of time(delay)-shifted copies of the data x, which represents the memory of the HAVOK model. Similar to an Auto-Regressive model, A longer memory allows for longer dependencies, but increases the complexity and computational intensity of the model.

c) rmax - the maximum rank of the HAVOK model, defined as the maximum number of singular values to retain when performing Singular Value Decomposition (SVD). A low rank model retains only the lower order statistics (moments) of the system, whereas a higher rank model also captures higher order moments and more detail. A higher-ranked model will have greater forecasting skill on both training and validation data, as the linear system asymptotically approximates the nonlinear system with increasing size, but it will make identification of an optimal ML method more difficult and might be prohibitevly expensive to run.

d) polyDegree - specifies the polynomial degree of the HAVOK-SINDy model. The standard HAVOK algorithm finds a linear representation in delay coordinates using least-squares regression, meaning that the algorithm tries to find a best-fit linear model _dvdt = Av_ in a least-squares sense, where each variable v_i is valued equally. Meanwhile, the HAVOK-SINDy algorithm tries to find the sparsest solution, where unimportant v_i variables are truncated (for more intuititon, google Least-Squares vs LASSO). (Note: Currently, only polynomial degrees of 1 are supported)

e) degOfSparsity - specifies the degree at which unimportant variables v_i are truncated in the HAVOK-SINDy algorithm.

f) MLmethod - specify which type of model is trained on the forcing term vr. The user may specify the following methods, including various ensemble methods and neural networks:

- Bagging (Bag)
- Boosting (LSBoost)
- Random Forest Regression (RFR)
- C++ Optimized Random Forest Regression (RFR-MEX) (Jaiantilal, 2010 and others)
- Support Vector Regression (SVR)
- Multilayer Perceptron (MLP)
- Long-Short Term Memory (LSTM)
- Temporal Convolutional Network (TCN) [unfinished]

g) D - The ML method uses previous values of the data x to predict the next value of vr. The parameter D specifies the spacing between these previous values. For example, if D = 5, the ML method uses [x(t), x(t-5dt), x(t-10dt), ...] to predict vr(t+dt). The number of x-predictors is limited by the stackmax of the HAVOK model.

![image](https://github.com/elise1993/sysidHAVOK/assets/100414021/77f77089-1638-4141-bf22-f2aafff3f192)

![image](https://github.com/elise1993/sysidHAVOK/assets/100414021/841c9f48-daaa-437b-ac53-acf2c77f9d2a)

h) For additional properties of the ML method, see the MATLAB documentation.

---

**models/**

Model functions for the Lorenz, Rossler, Van der Pol, Duffing, Double Pendulum, MackeyGlass, and MagneticFieldReversal systems.

---

**utils/partitionData.m**

Takes the data x and partitions it into training/validation/testing sets. Proportions of these may be specified.

---

**utils/sysidHAVOK.m**

Returns the matrices Xi,U,S representing a sparse Koopman-based linearization of the data x from a nonlinear system.

---

**utils/HankelMatrix.m, HankelSVD.m**

HankelMatrix.m produces a Hankel matrix of the data x, with _stackmax_ number of time-shifted (delayed) copies of the data x. HankelSVD assigns the matrix to the GPU if it is large enough and computes the SVD to produce the delay variables V in the coordinates US.

---

**utils/derivativeCentralDiff4.m**

Computes the discrete derivative of x(t) using a 4th order central difference scheme.

---

**utils/trainForcingModel.m, predictML.m**

These functions trains a ML method on the vr training data and makes predictions. Requires the specification of method (Bag,LSBoost,RFR,SVR,MLP,LSTM).

---

**utils/forecastHAVOK.m, forecastSkill.m**

forecastHAVOK.m performs a multi-step prediction of the HAVOK system trained by sysidHAVOK.m for the validation period, whereas forecastSkill.m checks the forecasting skill. For the Lorenz system, greater than 1000 multi-step predictions severely degrade the performance.

![image](https://github.com/elise1993/sysidHAVOK/assets/100414021/fce7964c-717f-4623-a03b-01dca94cc7b0)

![image](https://github.com/elise1993/sysidHAVOK/assets/100414021/08cd7b18-c1a5-4879-95e0-2bf40a9d9038)

---

**utils/recoverState.m**

Reproduces the original state x from the delay variables v, using the trained coordinates U and S from sysidHAVOK.m.

---

**utils/impulseHAVOK.m**

Produces and visualizes an impulse response of the system: dxdt = Ax + Bu with measurements y = Cx + Du, where u is a control variable and C and D defines the availability of x and u measurements. By default, the impulse forcing is simply set to the intermittent forcing for the validation period, which reproduces the validation data.

---

**utils/miscFunctions.m**

Class file containing convenient auxiliary functions used throughout the code.

---

**plotting/.**

Various plotting functions to reduce clutter within the main.m file.

**downloaded/.**

When sysidHAVOK.m is run, some files are automatically downloaded from other remote repositories and put here.

**data/.**

Files for pre-generated or collected data.

**tests/.**

Folder with hyperparameters used for the different systems.

---

# References

- Brunton & Kutz (2022) "Data-Driven Science and Engineering", Cambridge University Press, URL: [https://www.cambridge.org/highereducation/product/9781009089517/book]
- Yang et. al. (2022), "A Hybrid Method Using HAVOK Analysis and Machine Learning for Predicting Chaotic Time Series", Entropy (MDPI), URL: [https://www.mdpi.com/1099-4300/24/3/408]
- Mezić (2005), "Spectral properties of dynamical systems, model reduction and decompositions." Nonlinear Dynamics, URL: [https://link.springer.com/article/10.1007/s11071-005-2824-x]
- Gavish & Donoho (2014) "The Optimal Hard Threshold for Singular Values is 4/√3" , IEEE, URL: [https://ieeexplore.ieee.org/document/6846297]
- Molina-Cardín et. al. (2021) "Simple stochastic model for geomagnetic excursions and reversals reproduces the temporal asymmetry of the axial dipole moment", PNAS, URL: [https://www.pnas.org/doi/full/10.1073/pnas.2017696118]
- Jaiantilal (2010) "Random Forest (Regression, Classification and Clustering) implementation for MATLAB (and Standalone)", URL: [https://code.google.com/archive/p/randomforest-matlab/], Ported from Breiman et al. URL: [https://cran.r-project.org/web/packages/randomForest/index.html]
