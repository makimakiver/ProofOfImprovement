"use client";

import React, { useState } from 'react';
import { useRouter } from "next/navigation";

const SubmitResultPage = () => {
  const router = useRouter();
  
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [selectedResult, setSelectedResult] = useState('');
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [errors, setErrors] = useState({
    marketTitle: '',
    file: '',
    result: ''
  });

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0] || null;
    setSelectedFile(file);
    
    if (file) {
      const url = URL.createObjectURL(file);
      setPreviewUrl(url);
    } else {
      setPreviewUrl(null);
    }
  };

  const validateForm = () => {
    const newErrors = {
      marketTitle: '',
      file: '',
      result: ''
    };
    
    let isValid = true;
    
    if (!selectedFile) {
      newErrors.file = 'Please upload a photo of your result';
      isValid = false;
    }
    
    if (!selectedResult) {
      newErrors.result = 'Please select your result';
      isValid = false;
    }
    
    setErrors(newErrors);
    return isValid;
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    if (validateForm()) {
      console.log({
        selectedFile,
        selectedResult
      });
      
      alert('Result submitted successfully!');
      
      setSelectedFile(null);
      setSelectedResult('');
      setPreviewUrl(null);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md mx-auto bg-white rounded-lg shadow-md overflow-hidden">
        <div className="bg-blue-600 px-4 py-5 sm:px-6">
          <h1 className="text-xl font-bold text-white">Submit Your Result</h1>
        </div>
        
        <form onSubmit={handleSubmit} className="px-4 py-5 sm:p-6">
          <div className="mb-6">
            <p htmlFor="marketTitle" className="block text-xl font-medium text-gray-700 mb-1">
              Market Title
            </p>
          </div>
          
          <div className="mb-6">
            <label htmlFor="resultPhoto" className="block text-sm font-medium text-gray-700 mb-1">
              Upload Photo of Your Result
            </label>
            <div className={`mt-1 border-2 border-dashed rounded-md px-6 pt-5 pb-6 flex justify-center ${
              errors.file ? 'border-red-500' : 'border-gray-300'
            }`}>
              <div className="space-y-1 text-center">
                {previewUrl ? (
                  <div className="mb-3">
                    <img 
                      src={previewUrl} 
                      alt="Preview" 
                      className="mx-auto h-32 w-auto object-cover rounded-md"
                    />
                  </div>
                ) : (
                  <svg
                    className="mx-auto h-12 w-12 text-gray-400"
                    stroke="currentColor"
                    fill="none"
                    viewBox="0 0 48 48"
                    aria-hidden="true"
                  >
                    <path
                      d="M28 8H12a4 4 0 00-4 4v20m32-12v8m0 0v8a4 4 0 01-4 4H12a4 4 0 01-4-4v-4m32-4l-3.172-3.172a4 4 0 00-5.656 0L28 28M8 32l9.172-9.172a4 4 0 015.656 0L28 28m0 0l4 4m4-24h8m-4-4v8m-12 4h.02"
                      strokeWidth={2}
                      strokeLinecap="round"
                      strokeLinejoin="round"
                    />
                  </svg>
                )}
                
                <div className="flex text-sm text-gray-600">
                  <label
                    htmlFor="resultPhoto"
                    className="relative cursor-pointer bg-white rounded-md font-medium text-blue-600 hover:text-blue-500 focus-within:outline-none"
                  >
                    <span>Upload a file</span>
                    <input
                      id="resultPhoto"
                      name="resultPhoto"
                      type="file"
                      className="sr-only"
                      accept="image/*"
                      onChange={handleFileChange}
                    />
                  </label>
                  <p className="pl-1">or drag and drop</p>
                </div>
                <p className="text-xs text-gray-500">PNG, JPG, GIF up to 10MB</p>
              </div>
            </div>
            {errors.file && (
              <p className="mt-1 text-sm text-red-500">{errors.file}</p>
            )}
          </div>
          
          <div className="mb-6">
            <label htmlFor="result" className="block text-sm font-medium text-gray-700 mb-1">
              Select Your Result
            </label>
            <select
              id="result"
              className={`w-full px-3 py-2 border rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 ${
                errors.result ? 'border-red-500' : 'border-gray-300'
              }`}
              value={selectedResult}
              onChange={(e) => setSelectedResult(e.target.value)}
            >
              <option value="">-- Select a result --</option>
              <option value="A+">A+</option>
              <option value="A">A</option>
              <option value="B">B</option>
              <option value="C">C</option>
              <option value="D">D</option>
              <option value="E">E</option>
            </select>
            {errors.result && (
              <p className="mt-1 text-sm text-red-500">{errors.result}</p>
            )}
          </div>
          
          <div className="pt-4">
            <button
              type="submit"
              className="w-full px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
            >
              Submit Result
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default SubmitResultPage;
