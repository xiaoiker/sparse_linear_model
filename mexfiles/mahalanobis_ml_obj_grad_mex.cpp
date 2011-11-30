/*
 * mahalanobis_ml_obj_grad_mex.c
 *
 *  Created on: Apr 27, 2011
 *      Author: igkiou
 */

/*
#define __DEBUG__
*/

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <time.h>
#include <assert.h>

#include <mkl.h>
#include "mex.h"
#include "matrix.h"
#include "useblas.h"
#include "sparse_classification.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {

	/* Check number of input arguments */
	if (nrhs != 4) {
		ERROR("Four input arguments are required.");
    }

	/* Check number of output arguments */
	if (nlhs > 2) {
		ERROR("Too many output arguments.");
    }

	DOUBLE *X = (DOUBLE*) mxGetData(prhs[0]);
	DOUBLE *XXt = (DOUBLE*) mxGetData(prhs[1]);
	DOUBLE *XAtAXt = (DOUBLE*) mxGetData(prhs[2]);
	DOUBLE *normAAtSq = (DOUBLE*) mxGetData(prhs[3]);

	INT N = (INT) mxGetM(prhs[1]);

	if ((INT) mxGetNumberOfElements(prhs[0]) != N * N) {
		ERROR("Number of elements of M matrix does not match dimension size (first dimension of D matrix).");
	} else if ((INT) mxGetM(prhs[2]) != N) {
		ERROR("First dimension of DDt matrix does not match dimension size (first dimension of D matrix).");
	} else if ((INT) mxGetN(prhs[2]) != N) {
		ERROR("Second dimension of DDt matrix does not match dimension size (first dimension of D matrix).");
	}

	plhs[0] = mxCreateNumericMatrix(1, 1, MXPRECISION_CLASS, mxREAL);
	DOUBLE *obj = (DOUBLE *) mxGetData(plhs[0]);
	DOUBLE *deriv;
	INT derivFlag;

	if (nlhs == 2) {
		plhs[1] = mxCreateNumericMatrix(N * N, 1, MXPRECISION_CLASS, mxREAL);
		deriv = (DOUBLE *) mxGetData(plhs[1]);
		derivFlag = 1;
	} else {
		deriv = NULL;
		derivFlag = 0;
	}

	DOUBLE *MXXt = (DOUBLE *) MALLOC(N * N * sizeof(DOUBLE));
	DOUBLE *MXXtSq = (DOUBLE *) MALLOC(N * N * sizeof(DOUBLE));
	DOUBLE *MXAtAXt = (DOUBLE *) MALLOC(N * N * sizeof(DOUBLE));

	mahalanobis_ml_obj_grad(obj, deriv, X, XXt, XAtAXt, normAAtSq, N, derivFlag, MXXt, MXXtSq, MXAtAXt);

	FREE(MXXt);
	FREE(MXXtSq);
	FREE(MXAtAXt);
}
