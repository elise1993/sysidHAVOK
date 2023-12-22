This is a testbed for system identification and forecasting of dynamical systems using the Hankel Alternative View of Koopman (HAVOK) algorithm and Sparse Identification of Nonlinear Dynamics (SINDy). This code is based on the work by Brunton & Kutz (2022) and Yang et. al. (2022).

---

# Background

Any nonlinear dynamical system of the form dxdt = f(x(t)) may be represented by an infinite-dimensional linear system, defined by a so-called Koopman-operator (Mezić 2005). Finding an asymptotically large system like this is an ill-posed problem, which has led to the development of methods that attempt to approximate the Koopman operator. One such method is the Dynamic Mode Decomposition (DMD) and its extension, which have shown great promise at representing nonlinear and chaotic systems. DMD attempts to find a best-fit linear model between the current and next time step using regression, so that:

(1) dxdt = Ax

While the standard DMD is quite limited in representing nonlinear systems, extensions to the algorithm, such as extended DMD, allow for greater representation. Here, we focus on HAVOK, or Hankel DMD, which is one of the more recent developments. HAVOK organizes the data x into a Hankel matrix (a matrix of time-shifted copies of x), and then applies Singular Value Decomposition (SVD) and truncation to obtain a new coordinate system we call delay coordinates. These delay coordinates turn out to be highly useful for representing systems with long-term memory effects, which are prevalent in many dynamical systems. The variables in these coordinates, or delay variables, are denoted by v_i, so that the HAVOK model produces a truncated linear system of the following form, where B vr is a forcing term.

(2) dvdt = Av + Bvr

The term Av provides a good linear approximation of the nonlinear system, which can accurately model linear attractor dynamics on its own. The less we truncate the model (the larger we make A), the more accurately this linear model can represent the nonlinear dynamics as well. Two problems emerge here, (a) larger models require more data, and so we cannot just model everything with Av. (b) When the  Eq (2) is not a closed-form model, however, since the last delay variable vr is always poorly fitted during the regression procedure in HAVOK for a nonlinear system. As it turns out, while Av in (2) provides a linearized system that approximates attractor dynamics well, when its size is limited, it cannot approximate nonlinear dynamics well. vr corresponds to highly nonlinear intermittent phenomena. If vr is known, Eq (2) can accurately represent a nonlinear system, even when the model is highly truncated (small). As such, Yang et. al. (2022) suggested training a Machine Learning (ML) model on vr, and use it as a forcing term for the HAVOK model. This HAVOK-ML procedure has shown high promise in modelling nonlinear systems as is employed here.

---

# Files

**main.m**

This is the main code, which takes some data, interpolates it, partitions it into training/validation/testing sets, and finds a Koopman-based linear representation of the system in delay coordinates using HAVOK analysis and SINDy. This code requires the specification of the following parameters:

- x,t,x0 - Single-variable data, x, from a nonlinear chaotic system sampled at times t, with initial condition x0. Example data are generated from the Lorenz- and Van der Pol systems.

- stackmax - number of time(delay)-shifted copies of the data x, which represents the memory of the HAVOK model. Similar to an Auto-Regressive model, A longer memory allows for longer dependencies, but increases the complexity and computational intensity of the model.

- rmax - the maximum rank of the HAVOK model, defined as the maximum number of singular values to retain when performing Singular Value Decomposition (SVD). A low rank model retains only the lower order statistics (moments) of the system, whereas a higher rank model also captures higher order moments and more detail. A higher-ranked model will have greater forecasting skill on both training and validation data, as the linear system asymptotically approximates the nonlinear system with increasing size, but it will make identification of an optimal ML method more difficult and might be prohibitevly expensive to run.

- polyDegree - specifies the polynomial degree of the HAVOK-SINDy model. The standard HAVOK algorithm finds a linear representation in delay coordinates using least-squares regression, meaning that the algorithm tries to find a best-fit linear model _dvdt = Av_ in a least-squares sense, where each variable v_i is valued equally. Meanwhile, the HAVOK-SINDy algorithm tries to find the sparsest solution, where unimportant v_i variables are truncated (for more intuititon, google Least-Squares vs LASSO). (Note: Currently, only polynomial degrees of 1 are supported)

- degOfSparsity - specifies the degree at which unimportant variables v_i are truncated in the HAVOK-SINDy algorithm.

- MLmethod - specify which type of model is trained on the forcing term vr. The user may specify Random Forest Regression (RFR), Regression Trees, and various Neural Networks; Multilayer Perceptrons (MLPs), Long-Short Term Memory (LSTM) models, etc.

- treeSize/maxNumSplits - specifies properties of the ML method. In this case the number of ensembled trees and number of splits in those trees.

- D - The ML method uses previous values of the data x to predict the next value of vr. The parameter D specifies the spacing between these previous values. For example, if D = 5, the ML method uses [x(t), x(t-5dt), x(t-10dt), ...] to predict vr(t+dt). The number of x-predictors is limited by the stackmax of the HAVOK model.

---

**utils/generateLorenz.m, lorenzSystem.m, generateRossler.m, rosslerSystem.m**

Generates some nonlinear data x from the Lorenz and Rossler systems, using default parameters for chaotic conditions.

---

**utils/partitionData.m**

Takes the data x and partitions it into training/validation/testing sets. Proportions of these may be specified.

---

**utils/sysidHAVOK.m**

Returns the matrices Xi,U,S representing a sparse Koopman-based linearization of the data x from a nonlinear system.

---

**utils/HankelMatrix.m, HankelSVD.m**

Produces a Hankel matrix of the data x, with _stackmax_ number of time-shifted (delayed) copies of the data x. HankelSVD assigns the matrix to the GPU if it is large enough and computes the SVD to produce the delay variables V in the coordinates US.

---

**utils/derivativeCentralDiff4.m**

Computes the discrete derivative of x(t) using a 4th order central difference scheme.

---

**utils/trainForcingModel.m**

Trains a ML method on the vr training data. Requires the specification of method (Random Forest Regression, Regression Tree, Multilayer Perceptron, LSTM, etc.). The properties and layers of these methods may be edited manually.

---

**utils/recoverState.m**

Reproduces the original state x from the delay variables v, using the trained coordinates U and S from sysidHAVOK.m.

---

**utils/impulseHAVOK.m**

Produces and visualizes an impulse response of the system: dxdt = Ax + Bu with measurements y = Cx + Du, where u is a control variable and C and D defines the availability of x and u measurements.

---

**utils/miscFunctions.m**

Class file containing convenient auxiliary functions used throughout the code.

---

**plotting/.**

Various plotting functions to reduce clutter within the main.m file.

---

# References

- Brunton & Kutz, 2022, "Data-Driven Science and Engineering", Cambridge University Press, URL: [https://www.cambridge.org/highereducation/product/9781009089517/book]
- Yang et. al. (2022), "A Hybrid Method Using HAVOK Analysis and Machine Learning for Predicting Chaotic Time Series", Entropy (MDPI), URL: [https://www.mdpi.com/1099-4300/24/3/408]
- Mezić (2005), "Spectral properties of dynamical systems, model reduction and decompositions." Nonlinear Dynamics, URL: [https://link.springer.com/article/10.1007/s11071-005-2824-x]

