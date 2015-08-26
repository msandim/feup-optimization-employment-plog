# Employee hiring optimization solution

This repository contains a solution to an employee hiring optimization problem using Constraint Logic Programming, developed on the "Logic Programming" course at FEUP. The development plataform used was Sicstus Prolog 4.3.0, along with the "clpfd" library for Constraint Logic Programming in Prolog.

This project was developed by [JPMMaia](https://github.com/JPMMaia) and [msandim](https://github.com/msandim).

For further information on the topics of this project, check the [report](https://github.com/msandim/optimization-employment-plog/raw/master/resources/report.pdf) (portuguese only).

## 1. Problem description

The problem being addressed in this solution relates to employee hiring: an imaginary company needs several employees during a work day, which can be of two types:
* Fulltime employees: work all day, with 1 free luch hour. May work on their lunch hour for a bonus;
* Part-time employees: work 3 hours, with no lunch hour May work an extra hour for a bonus.

The number of employees working in their lunch hour or working extra hours are limited by the Workers Union. The number of part-time employees is limited by number and ratio when compared to the number of fulltime employees.

**An optimal solution to this problem is the employee configuration that costs less (in terms of salaries to pay) to the company.**

## 2. Dataset

The dataset involved in this project (including training and testing sets) is described and available for download [here](https://archive.ics.uci.edu/ml/datasets/Parkinson+Speech+Dataset+with++Multiple+Types+of+Sound+Recordings) and includes several features from patient voice recordings (vowels, numbers, short sentences and words). The "UPDRS" feature was ignored in this analysis.

## 3. Learning algorithm

In order to find the connection weights that minimize the model's cost function, the Backpropagation algorithm was used. The minimization step is based on the Gradient Descent algorithm, with an added "momentum" term that avoids imprisonments in local minimums of the cost function (which may not be convex).

More information on this algorithm is available here:
> Fausett, Laurene. Fundamentals of neural networks: architectures, algorithms, and applications. Prentice-Hall, Inc., 1994.

## 4. Command line interface

![gui](https://github.com/msandim/neural-net-iart/blob/master/resources/gui.png?raw=true)

The interface allows the user to modify the:
* Number of neurons on each hidden layer;
* Learning rate and momentum values;
* Train and test data paths;
* Medium Squared Error value to achieve convergence in the algorithm;
* Maximum number of iterations;
* Types of recordings present on the train and test phases.

On the right panel, the MSE for the training set on each iteration is showed, along with the number of well-classified cases. After the training process is concluded, the same information is reported for the test set.
