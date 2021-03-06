/*
 * nmmds_apg_mex.c
 *
 *  Created on: Aug 6, 2011
 *      Author: igkiou
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>

#include "sparse_classification.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {

	/* Check number of input arguments */
	if (nrhs > 13) {
		ERROR("Thirteen or fewer input arguments are required.");
    } else if (nrhs < 5) {
		ERROR("At least five input arguments are required.");
    }

	/* Check number of output arguments */
	if (nlhs > 1) {
		ERROR("Too many output arguments.");
    }

	INT numPoints = (INT) * (DOUBLE *) mxGetData(prhs[0]);
	CHAR distLabelName;
	if (mxGetNumberOfElements(prhs[1]) != 0) {
		if (!mxIsChar(prhs[1])) {
			ERROR("Second argument must be of type CHAR.");
		}
		distLabelName = (CHAR)*(CHAR*) mxGetData(prhs[1]);
	} else {
		distLabelName = 'R';
	}
	DOUBLE *matlabConstraintMat = (DOUBLE*) mxGetData(prhs[2]);
	DOUBLE *weights = (DOUBLE*) mxGetData(prhs[3]);
	DOUBLE *tau = (DOUBLE*) mxGetData(prhs[4]);

	INT numConstraints = (INT) mxGetM(prhs[2]);
	INT numRepeats = (INT) mxGetNumberOfElements(prhs[4]);

	DOUBLE tolerance;
	if ((nrhs >= 6) && (mxGetNumberOfElements(prhs[5]) != 0)) {
		tolerance = *(DOUBLE*) mxGetData(prhs[5]);
	} else {
		tolerance = 0.00001;
	}

	DOUBLE delta;
	if ((nrhs >= 7) && (mxGetNumberOfElements(prhs[6]) != 0)) {
		delta = *(DOUBLE*) mxGetData(prhs[6]);
	} else {
		delta = 0.1;
	}

	INT numIters;
	if ((nrhs >= 8) && (mxGetNumberOfElements(prhs[7]) != 0)) {
		numIters = (INT)*(DOUBLE*) mxGetData(prhs[7]);
	} else {
		numIters = 50000;
	}

	INT rankIncrement;
	if ((nrhs >= 9) && (mxGetNumberOfElements(prhs[8]) != 0)) {
		rankIncrement = (INT)*(DOUBLE*) mxGetData(prhs[8]);
	} else {
		rankIncrement = - 1;
	}

	INT lineSearchFlag;
	if ((nrhs >= 10) && (mxGetNumberOfElements(prhs[9]) != 0)) {
		lineSearchFlag = (INT)*(DOUBLE*) mxGetData(prhs[9]);
	} else {
		lineSearchFlag = 0;
	}

	DOUBLE eta;
	if ((nrhs >= 11) && (mxGetNumberOfElements(prhs[10]) != 0)) {
		eta = *(DOUBLE*) mxGetData(prhs[10]);
	} else {
		eta = 1.1;
	}

	DOUBLE tauMultiplier;
	if ((nrhs >= 12) && (mxGetNumberOfElements(prhs[11]) != 0)) {
		tauMultiplier = *(DOUBLE*) mxGetData(prhs[11]);
	} else {
		tauMultiplier = 10000;
	}

	DOUBLE tauRate;
	if ((nrhs >= 13) && (mxGetNumberOfElements(prhs[12]) != 0)) {
		tauRate = *(DOUBLE*) mxGetData(prhs[12]);
	} else {
		tauRate = 0.9;
	}

	if ((mxGetNumberOfElements(prhs[3]) != 0) && \
		(mxGetNumberOfElements(prhs[3]) != numConstraints)) {
		ERROR("First dimension of vector weights does not match number of constraints (first dimension of constraint matrix).");
	}

	INT *constraintMat;
	DOUBLE *betaVec;
	DIST_LABEL_TYPE distLabelType = convertDistLabelName(distLabelName);
	if (distLabelType == DIST_LABEL_TARGETS) {
		if (mxGetN(prhs[2]) != 3) {
			ERROR("Constraint matrix does not meet specified format: second dimension not equal to three.");
		}
		constraintMat = (INT *) MALLOC(numConstraints * 2 * sizeof(INT));
		betaVec = (DOUBLE *) MALLOC(numConstraints * 1 * sizeof(DOUBLE));
	} else if (distLabelType == DIST_LABEL_BOUNDS) {
		if (mxGetN(prhs[2]) != 4) {
			ERROR("Constraint matrix does not meet specified format: second dimension not equal to four.");
		}
		constraintMat = (INT *) MALLOC(numConstraints * 3 * sizeof(INT));
		betaVec = (DOUBLE *) MALLOC(numConstraints * 1 * sizeof(DOUBLE));
	} else if ((distLabelType == DIST_LABEL_RELATIONAL) \
				|| (distLabelType == DIST_LABEL_SQRHINGE) \
				|| (distLabelType == DIST_LABEL_HUBERHINGE)) {
		if (mxGetN(prhs[2]) != 5) {
			ERROR("Constraint matrix does not meet specified format: second dimension not equal to five.");
		}
		constraintMat = (INT *) MALLOC(numConstraints * 4 * sizeof(INT));
		betaVec = (DOUBLE *) MALLOC(numConstraints * 1 * sizeof(DOUBLE));
	}
	convertDistanceLabelMat(constraintMat, betaVec, distLabelType, \
					matlabConstraintMat, numConstraints, numPoints);

	plhs[0] = mxCreateNumericMatrix(numPoints, numPoints, MXPRECISION_CLASS, mxREAL);
	DOUBLE *K = (DOUBLE *) mxGetData(plhs[0]);

	if (numRepeats > 1) {
		nrkl_apg(K, distLabelType, constraintMat, betaVec, weights, tau, delta, \
				numIters, tolerance, lineSearchFlag, eta, numPoints, \
				numConstraints, numRepeats);
	} else {
		nrkl_apg_continuation(K, distLabelType, constraintMat, betaVec, weights, \
				*tau, delta, numIters, tolerance, lineSearchFlag, eta, \
				tauMultiplier, tauRate, numPoints, numConstraints);
	}

	FREE(constraintMat);
	FREE(betaVec);
}
