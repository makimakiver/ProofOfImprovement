"use client";

import React, { useState } from 'react';
import useSubmitTransaction from "~~/hooks/scaffold-move/useSubmitTransaction";

const ValidateResultPage = () => {
  const { submitTransaction, transactionResponse, transactionInProcess } = useSubmitTransaction("TestMarketAbstraction");

  const [isInvalidModalOpen, setIsInvalidModalOpen] = useState(false);
  const [invalidReason, setInvalidReason] = useState('different-score');
  const [differentScore, setDifferentScore] = useState('');
  const [otherReason, setOtherReason] = useState('');
  
  const resultData = {
    marketTitle: "marketTitle",
    resultImage: "/samplephoto.png",
    selectedResult: "A"
  };

  const handleValidClick = async () => {
    try {
      await submitTransaction("new_respond_validation", [process.env.NEXT_PUBLIC_REGISTRY_ACCOUNT_ADDRESS, true, "", 0]);

      if (transactionResponse?.transactionSubmitted) {
        console.log("Transaction successful:", transactionResponse.success ? "success" : "failed");
      }
    } catch (error) {
      console.error("Error submitTransaction:", error);
    }
  };

  const handleInvalidClick = () => {
    setIsInvalidModalOpen(true);
  };

  const handleCancelModal = () => {
    setIsInvalidModalOpen(false);
    setInvalidReason('different-score');
    setDifferentScore('');
    setOtherReason('');
  };

  const handleSubmitInvalidReason = () => {
    if (invalidReason === 'different-score' && !differentScore) {
      alert('Please select the correct score');
      return;
    }
    
    if (invalidReason === 'other' && !otherReason.trim()) {
      alert('Please provide a reason');
      return;
    }
    
    const reasonData = invalidReason === 'different-score' 
      ? { reason: 'different-score', correctScore: differentScore }
      : { reason: 'other', explanation: otherReason };
      
    console.log('Invalid reason submitted:', reasonData);
    alert('Submission marked as invalid');
    setIsInvalidModalOpen(false);
    
    setInvalidReason('different-score');
    setDifferentScore('');
    setOtherReason('');
  };

  return (
    <div className="min-h-screen bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-lg mx-auto bg-white rounded-lg shadow-md overflow-hidden">
        <div className="bg-blue-600 px-6 py-4">
          <h1 className="text-xl font-bold text-white">Validate Result</h1>
        </div>
        
        <div className="px-6 py-6">
          <div className="mb-6">
            <h2 className="text-lg font-medium text-gray-900 mb-1">Market Title</h2>
            <p className="text-gray-700">{resultData.marketTitle}</p>
          </div>
          
          <div className="mb-6">
            <h2 className="text-lg font-medium text-gray-900 mb-2">Submitted Result Photo</h2>
            <div className="border rounded-lg overflow-hidden">
              <img 
                src={resultData.resultImage} 
                alt="Result" 
                className="w-full h-auto"
              />
            </div>
          </div>
          
          <div className="mb-8">
            <h2 className="text-lg font-medium text-gray-900 mb-1">Selected Result</h2>
            <div className="inline-flex items-center justify-center w-12 h-12 rounded-full bg-blue-100 text-blue-800 text-xl font-semibold">
              {resultData.selectedResult}
            </div>
          </div>
          
          <div className="flex space-x-4">
            <button
              onClick={handleValidClick}
              className="flex-1 px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500"
            >
              Valid
            </button>
            <button
              onClick={handleInvalidClick}
              className="flex-1 px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
            >
              Invalid
            </button>
          </div>
        </div>
      </div>
      
      {isInvalidModalOpen && (
        <div className="fixed inset-0 z-10 overflow-y-auto">
          <div className="flex items-center justify-center min-h-screen px-4 pt-4 pb-20 text-center">
            <div className="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" onClick={handleCancelModal}></div>
            
            <div className="relative bg-white rounded-lg px-4 pt-5 pb-4 text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:max-w-lg sm:w-full sm:p-6">
              <div>
                <h3 className="text-lg font-medium text-gray-900 mb-4">Why Invalid?</h3>
                
                <div className="space-y-4">
                  <div className="flex items-start">
                    <div className="flex items-center h-5">
                      <input
                        id="different-score"
                        name="invalid-reason"
                        type="radio"
                        className="h-4 w-4 text-blue-600 border-gray-300 rounded"
                        checked={invalidReason === 'different-score'}
                        onChange={() => setInvalidReason('different-score')}
                      />
                    </div>
                    <div className="ml-3 flex items-center">
                      <label htmlFor="different-score" className="font-medium text-gray-700 mr-3">
                        Score is different:
                      </label>
                      <select
                        value={differentScore}
                        onChange={(e) => setDifferentScore(e.target.value)}
                        className="mt-1 block w-36 pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm rounded-md"
                        disabled={invalidReason !== 'different-score'}
                      >
                        <option value="">Select Grade</option>
                        <option value="A+">A+</option>
                        <option value="A">A</option>
                        <option value="B">B</option>
                        <option value="C">C</option>
                        <option value="D">D</option>
                        <option value="E">E</option>
                      </select>
                    </div>
                  </div>
                  
                  <div className="flex items-start">
                    <div className="flex items-center h-5">
                      <input
                        id="other-reason"
                        name="invalid-reason"
                        type="radio"
                        className="h-4 w-4 text-blue-600 border-gray-300 rounded"
                        checked={invalidReason === 'other'}
                        onChange={() => setInvalidReason('other')}
                      />
                    </div>
                    <div className="ml-3 text-sm w-full">
                      <label htmlFor="other-reason" className="font-medium text-gray-700">
                        Other
                      </label>
                      <textarea
                        value={otherReason}
                        onChange={(e) => setOtherReason(e.target.value)}
                        rows={3}
                        className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                        placeholder="Please explain why this result is invalid..."
                        disabled={invalidReason !== 'other'}
                      />
                    </div>
                  </div>
                </div>
              </div>
              
              <div className="mt-5 sm:mt-6 sm:grid sm:grid-cols-2 sm:gap-3">
                <button
                  type="button"
                  className="w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 sm:text-sm"
                  onClick={handleCancelModal}
                >
                  Cancel
                </button>
                <button
                  type="button"
                  className="mt-3 w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-blue-600 text-base font-medium text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 sm:mt-0 sm:text-sm"
                  onClick={handleSubmitInvalidReason}
                >
                  Submit
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default ValidateResultPage;